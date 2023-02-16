module JABA

module OS
  def self.windows? = true
  def self.mac? = false
end

def self.set_context(c) = @@context = c
def self.context = @@context

@@running_tests = false
def self.running_tests! = @@running_tests = true
def self.running_tests? = @@running_tests

def self.error(msg, errobj: nil, want_backtrace: true)
  e = JabaError.new(msg)
  e.set_backtrace(Array(errobj&.src_loc || caller))
  e.instance_variable_set(:@want_backtrace, want_backtrace)
  raise e
end

def self.warn(...)
  JABA.context.warn(...)
end

def self.log(...)
  JABA.context.log(...)
end

class Context
  def initialize(want_exceptions, &block)
    JABA.set_context(self)
    @want_exceptions = want_exceptions
    @input_block = block
    @invoking_dir = Dir.getwd.freeze
    @input = Input.new
    @input.instance_variable_set(:@build_root, nil)
    @input.instance_variable_set(:@src_root, nil)
    @input.instance_variable_set(:@definitions, [])
    @input.instance_variable_set(:@global_attrs, {})
    @src_root = @build_root = @temp_dir = nil
    @output = {}
    @warnings = []
    @log_msgs = []# JABA.running_tests? ? nil : [] # Disable logging when running tests
    @file_manager = FileManager.new
    @jdl_files = []
    @jdl_includes = []
    @jdl_file_lookup = {}
    @executing_jdl = false
  end

  def input = @input
  def output = @output
  def invoking_dir = @invoking_dir
  def src_root = @src_root
  def build_root = @build_root
  def temp_dir = @temp_dir
  def file_manager = @file_manager

  def execute
    begin
      run
    rescue Exception => e
      e = e.cause if e.cause
      log e.full_message(highlight: false), :ERROR
      bt = @executing_jdl ? get_jdl_backtrace(e.backtrace) : e.backtrace
      want_backtrace = !@executing_jdl
      info = case e
      when JabaError
        want_backtrace = e.instance_variable_get(:@want_backtrace)
        make_error_info(e.message, bt)
      when ScriptError # script errors do not have backtraces
        make_error_info(e.message, bt, err_type: :syntax)
      else
        make_error_info(e.message, bt)
      end
      output[:error] = want_backtrace ? info.full_message : info.message
      if @want_exceptions
        e = JabaError.new(info.message)
        e.instance_variable_set(:@file, info.file)
        e.instance_variable_set(:@line, info.line)
        e.set_backtrace(bt)
        raise e
      end
    ensure
      term_log
    end
  end

  def run
    log "Starting Jaba at #{Time.now.strftime("%Y-%m-%d %H:%M:%S")}", section: true
    
    @input_block&.call(input)
    
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
    @top_level_node = Node.new(JDL::TopLevelAPI, 'top_level')
    JDL::TopLevelAPI.singleton.__internal_set_node(@top_level_node)

    init_root_paths
    load_jaba_files
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
      invoking_dir if !JABA.running_tests?
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

  def load_jaba_files
    if src_root
      process_load_path(src_root, fail_if_empty: true)
    end

    # Definitions can also be provided in a block form
    #
    Array(input.definitions).each do |block|
      block_file = block.source_location[0].cleanpath
      @jdl_files << block_file
      execute_jdl(&block)
    end

    # Process include directives, accounting for included files including other files.
    #
    while !@jdl_includes.empty?
      inc = @jdl_includes.pop
      process_load_path(inc.path)
    end
  end

  def process_load_path(p, fail_if_empty: false)
    if !p.absolute_path?
      JABA.error("'#{p}' must be an absolute path")
    end

    if !@file_manager.exist?(p)
      JABA.error("'#{p}' does not exist", want_backtrace: false)
    end

    if @file_manager.directory?(p)
      files = @file_manager.glob_files("#{p}/*.jaba")
      if files.empty?
        msg = "No .jaba files found in '#{p}'"
        if fail_if_empty
          JABA.error(msg, want_backtrace: false)
        else
          JABA.warn(msg)
        end
      else
        files.each do |f|
          process_jaba_file(f)
        end
      end
    else
      process_jaba_file(p)
    end
  end

  def process_jaba_file(f)
    if !f.absolute_path?
      JABA.error("'#{f}' must be an absolute path")
    end
    f = f.cleanpath

    if @jdl_file_lookup.has_key?(f)
      return # Already loaded. Ignore.
    end
    
    @jdl_file_lookup[f] = nil
    @jdl_files << f

    execute_jdl(file: f)
  end

  IncludeInfo = Data.define(:path, :args)

  def process_include(path)
    if path.nil?
      JABA.error("include requires a path")
    end
    if !path.absolute_path?
      path = "#{$last_call_location.absolute_path.parent_path}/#{path}"
    end
    if path.wildcard?
      @jdl_includes.concat(@file_manager.glob_files(path).map{|d| IncludeInfo.new(d, args)})
    else
      @jdl_includes << IncludeInfo.new(p ath, args)
    end
  end

  def execute_jdl(*args, file: nil, str: nil, &block)
    @executing_jdl = true
    if str
      JDL::TopLevelAPI.singleton.instance_eval(str, file)
    elsif file
      log "Executing #{file}"
      JDL::TopLevelAPI.singleton.instance_eval(file_manager.read(file), file)
    end
    if block_given?
      JDL::TopLevelAPI.singleton.instance_exec(*args, &block)
    end
    @executing_jdl = false
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

  def warn(msg, errobj: nil)
    callstack = Array(errobj&.src_loc || caller)
    jdl_bt = get_jdl_backtrace(callstack)
    if jdl_bt.empty?
      msg = "Warning: #{msg}"
    else
      msg = make_error_info(msg, jdl_bt, err_type: :warning).message
    end
    log(msg, :WARN)
    @warnings << msg
    nil
  end

  def get_jdl_backtrace(callstack)
    # Clean up callstack which could be in 'caller' or 'caller_locations' form.
    #
    callstack = callstack.map do |l|
      if l.is_a?(::Thread::Backtrace::Location)
        "#{l.absolute_path}:#{l.lineno}"
      else
        l
      end
    end

    # Extract any lines in the callstack that contain references to definition source files.
    #
    jdl_bt = callstack.select {|c| @jdl_files.any? {|sf| c.include?(sf)}}

    # remove the unwanted ':in ...' suffix from user level definition errors
    #
    jdl_bt.map!{|l| l.clean_backtrace}
    
    # Can contain unhelpful duplicates due to loops, make unique.
    #
    jdl_bt.uniq!
    jdl_bt
  end

  ErrorInfo = Data.define(:message, :full_message, :file, :line)

  def make_error_info(msg, backtrace, err_type: :error)
    if err_type == :syntax
      # With ruby ScriptErrors there is no useful callstack. The error location is in the msg itself.
      #
      err_line = msg

      # Delete ruby's way of reporting syntax errors in favour of our own
      #
      msg = msg.sub(/^.* syntax error, /, '')
    else
      err_line = backtrace[0]
    end
    
    # Extract file and line information from the error line.
    #
    if err_line !~ /^(.+):(\d+)/
      raise "Could not extract file and line number from '#{err_line}'"
    end

    file = Regexp.last_match(1)
    line = Regexp.last_match(2).to_i

    m = String.new
    
    m << case err_type
    when :error
      'Error'
    when :warning
      'Warning'
    when :syntax
      'Syntax error'
    else
      raise "Invalid error type '#{err_type}'"
    end
    
    m << ' at'
    m << " #{file.basename}:#{line}"
    m << ": #{msg}"
    if m =~ /[a-zA-Z0-9']$/
      m.ensure_end_with!('.')
    end

    # Format full message, which includes backtrace. First backtrace entry is the error line
    # which has already been reported in the main error line, so only show the backtrace if it
    # contains more than one item.
    #
    fm = String.new(m)
    if backtrace.size > 1
      fm << "\nTrace:\n"
      backtrace.each do |bt|
        fm << "  " << bt << "\n"
      end
    end
    
    ErrorInfo.new(m, fm, file, line)
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

  def include_shared(id)
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
