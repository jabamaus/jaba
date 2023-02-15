module JABA

def self.error(msg, errobj: nil, callstack: nil, syntax: false, want_backtrace: true)
  e = JabaError.new(msg)
  e.instance_variable_set(:@callstack, Array(errobj&.src_loc || callstack || caller))
  e.instance_variable_set(:@syntax, syntax)
  e.instance_variable_set(:@want_backtrace, want_backtrace)
  raise e
end

class Context
  def initialize(want_exceptions, test_mode)
    @want_exceptions = want_exceptions
    @test_mode = test_mode
    @invoking_dir = Dir.getwd.freeze
    @input = Input.new
    @input.instance_variable_set(:@build_root, nil)
    @input.instance_variable_set(:@src_root, nil)
    @input.instance_variable_set(:@definitions, [])
    @input.instance_variable_set(:@global_attrs, {})
    @src_root = @build_root = @temp_dir = nil
    @output = {}
    @warnings = []
    @log_msgs = test_mode? ? nil : [] # Disable logging when running tests
  end

  def input = @input
  def output = @output
  def test_mode? = @test_mode
  def invoking_dir = @invoking_dir
  def src_root = @src_root
  def build_root = @build_root
  def temp_dir = @temp_dir
  def file_manager = @file_manager

  def execute
    begin
      run
    rescue => e
      e = e.cause if e.cause
      output[:error] = e.full_message
      log e.full_message(highlight: false), :ERROR
      raise if @want_exceptions
    ensure
      term_log
    end
  end

  def run
    log "Starting Jaba at #{Time.now.strftime("%Y-%m-%d %H:%M:%S")}", section: true
    
    duration = Kernel.milli_timer do
      profile(input.profile?) do
        do_run
      end
    end

    file_manager.include_untracked # Include all generated files for the purpose of reporting back to the user

    # Make files that will be reported back to the user relative to build_root
    #
    generated = file_manager.generated.map{|f| f.relative_path_from(build_root)}
    added = file_manager.added.map{|f| f.relative_path_from(build_root)}.sort_no_case!
    modified  = file_manager.modified.map{|f| f.relative_path_from(build_root)}.sort_no_case!
    unchanged = file_manager.unchanged.map{|f| f.relative_path_from(build_root)}.sort_no_case!

    summary = "Generated #{generated.size} files, #{added.size} added, #{modified.size} modified, #{unchanged.size} unchanged in #{duration}"
    summary << "\n"

    added.each do |f|
      summary << "  #{f} [A]\n"
    end
    modified.each do |f|
      summary << "  #{f} [M]\n"
    end
    if input.verbose?
      unchanged.each do |f|
        summary << "  #{f} [UNCHANGED]\n"
      end
    end

    log summary
    log "Done! (#{duration})"

    output[:added] = added
    output[:modified] = modified
    output[:unchanged] = unchanged
    output[:summary] = summary
    output[:warnings] = @warnings.uniq # Strip duplicate warnings
  end

  def do_run
    @file_manager = FileManager.new(self)
    @load_manager = LoadManager.new(self, @file_manager)
    @top_level_node = Node.new(JDL::TopLevelAPI, 'top_level')
    JDL::TopLevelAPI.singleton.__internal_set_node(@top_level_node)

    JDL.constants.sort.each do |c|
      if c.end_with?('API')
        klass = JDL.const_get(c)
        klass.singleton.__internal_set_context(self)
      end
    end

    init_root_paths
    @load_manager.load_jaba_files
  end

  def init_root_paths
    # Initialise build_root from command line or if not present to $(cwd)/buildsystem, and ensure it exists
    #
    @build_root = if input.build_root.nil?
      "#{invoking_dir}/buildsystem"
    else
      input.build_root.to_absolute(base: invoking_dir, clean: true)
    end
    build_root.freeze

    @temp_dir = "#{build_root}/.jaba"
    FileUtils.makedirs(temp_dir) if !File.exist?(temp_dir)

    @src_root = if input.src_root.nil?
      invoking_dir if !test_mode?
    else
      input.src_root.to_absolute(base: invoking_dir, clean: true)
    end

    if src_root
      src_root.freeze
       if !File.exist?(src_root)
        JABA.error("source root '#{src_root}' does not exist", want_backtrace: false)
       end
    end

    log "src_root=#{src_root}"
    log "build_root=#{build_root}"
    log "temp_dir=#{temp_dir}"
  end

  def execute_jdl(*args, file: nil, str: nil, &block)
    if str
      JDL::TopLevelAPI.singleton.instance_eval(str, file)
    elsif file
      log "Executing #{file}"
      JDL::TopLevelAPI.singleton.instance_eval(file_manager.read(file), file)
    end
    if block_given?
      JDL::TopLevelAPI.singleton.instance_exec(*args, &block)
    end
  rescue JabaError
    raise # Prevent fallthrough to next case
  rescue StandardError => e # Catches errors like invalid constants
    JABA.error(e.message, callstack: e.backtrace)
  rescue ScriptError => e # Catches syntax errors. In this case there is no backtrace.
    JABA.error(e.message, syntax: true)
  end

  def log(msg, severity = :INFO, section: false)
    return if !@log_msgs
    if section
      max_width = 130
      n = ((max_width - msg.size)/2).round
      if n > 2
        msg = "#{'=' * n} #{msg} #{'=' * n}"
      end
    end
    @log_msgs << "#{severity} #{msg}"
  end

  def term_log
    return if !@log_msgs
    log_fn = "#{temp_dir}/jaba.log"
    if File.exist?(log_fn)
      File.delete(log_fn)
    else
      FileUtils.makedirs(log_fn.parent_path)
    end
    IO.write(log_fn, @log_msgs.join("\n"))
  end

  def validate_id(id, what)
    if !(id.symbol? || id.string?) || id !~ /^[a-zA-Z0-9_\-.|]+$/
      msg = if id.nil?
        "'#{what}' requires an id"
      else
        "'#{id}' is an invalid id"
      end
      msg << ". Must be an alphanumeric string or symbol (-_. permitted), eg :my_id, 'my-id', 'my.id'"
      JABA.error(msg)
    end
  end

  def create_node(api_klass, *args, **kwargs, &block)
    id = args.shift
    validate_id(id, :node)
    node = Node.new(api_klass, id, &block)
  end

  # TODO: move to jrf
  def profile(enabled)
    if !enabled
      yield
      return
    end

    begin
      require 'ruby-prof'
    rescue LoadError
      JABA.error( "ruby-prof gem is required to run with --profile. Could not be loaded.", want_backtrace: false)
    end

    puts 'Invoking ruby-prof...'
    RubyProf.start
    yield
    result = RubyProf.stop
    file = "#{temp_dir}/jaba.profile"
    str = String.new
    puts "Write profiling results to #{file}..."
    [RubyProf::FlatPrinter, RubyProf::GraphPrinter].each do |p|
      printer = p.new(result)
      printer.print(str)
    end
    IO.write(file, str)
  end

end ; end
