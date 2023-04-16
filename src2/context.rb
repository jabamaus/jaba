module JABA
  def self.set_context(c) = @@context = c
  set_context(nil)
  def self.context = @@context

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
      @warnings = []
      @warning_lookup = {}
      @output = {warnings: @warnings, error: nil}
      @log_msgs = [] # JABA.running_tests? ? nil : [] # Disable logging when running tests
      @file_manager = FileManager.new
      @jdl_files = []
      @jdl_includes = []
      @jdl_file_lookup = {}
      @node_defs = []
      @executing_jdl = false
      @attr_default_read_stack = []
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
        profile(input.profile?) do
          run
        end
      rescue StandardError, ScriptError, JabaError => e
        log e.full_message(highlight: false), :ERROR
        bt = @executing_jdl ? get_jdl_backtrace(e.backtrace) : e.backtrace
        want_backtrace = !@executing_jdl
        want_backtrace = e.instance_variable_get(:@want_backtrace) if e.is_a?(JabaError)
        want_err_line = true
        want_err_line = e.instance_variable_get(:@want_err_line) if e.is_a?(JabaError)
        info = make_error_info(e.message, bt, exception: e, want_err_line: want_err_line)
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
      duration = milli_timer do
        do_run
      end

      file_manager.include_untracked # Include all generated files for the purpose of reporting back to the user

      # Make files that will be reported back to the user relative to build_root
      #
      generated = file_manager.generated.map { |f| f.relative_path_from(build_root) }
      added = file_manager.added.map { |f| f.relative_path_from(build_root) }.sort_no_case!
      modified = file_manager.modified.map { |f| f.relative_path_from(build_root) }.sort_no_case!
      unchanged = file_manager.unchanged.map { |f| f.relative_path_from(build_root) }.sort_no_case!

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
    end

    def do_run
      log "Starting Jaba at #{Time.now}", section: true
      @input_block&.call(input)
      init_root_paths

      @top_level_node = Node.new(JDL::TopLevelAPI, "top_level", nil, nil)
      @output[:root] = @top_level_node
      JDL::TopLevelAPI.singleton.__internal_set_node(@top_level_node)

      set_top_level_attrs_from_input

      @executing_jdl = true
      load_jaba_files

      @top_level_node.post_create
      @default_configs = @top_level_node[:configs]

      @node_defs.each do |nd|
        process_node_def(nd)
      end
      @executing_jdl = false

      @top_level_node.visit do |n|
        n.attributes.each do |a|
          a.process_flags
        end
      end
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

    def set_top_level_attrs_from_input
      input.global_attrs&.each do |name, values|
        values = Array(values).map { |e| e.to_s }

        attr = @top_level_node.get_attr(name.to_s, fail_if_not_found: false)
        if attr.nil?
          JABA.error("'#{name}' attribute not defined in :globals type", want_backtrace: false)
        end

        attr_def = attr.attr_def
        type = attr_def.attr_type
        case attr_def.variant
        when :single
          if values.size > 1
            JABA.error("'#{name}' attribute only expects one value but #{values.inspect} provided", want_backtrace: false)
          end
          value = type.from_cmdline(values[0], attr_def)
          if attr.type_id == :file || attr.type_id == :dir
            value = value.to_absolute(base: invoking_dir, clean: true) # TODO: need to do this for array/hash elems too
          end
          attr.set(value)
        when :array
          if values.empty?
            JABA.error("'#{name}' array attribute requires one or more values", want_backtrace: false)
          end
          attr.set(values.map { |v| type.from_cmdline(v, attr_def) })
        when :hash
          if values.empty? || values.size % 2 != 0
            JABA.error("'#{name}' hash attribute requires one or more pairs of values", want_backtrace: false)
          end
          key_type = attr.attr_def.attr_key_type
          values.each_slice(2) do |kv|
            key = key_type.from_cmdline(kv[0], attr_def)
            value = type.from_cmdline(kv[1], attr_def)
            attr.set(key, value)
          end
        end
      end
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
        path = "#{$last_call_location.src_loc_info[0].parent_path}/#{path}"
      end
      if path.wildcard?
        @jdl_includes.concat(@file_manager.glob_files(path).map { |d| IncludeInfo.new(d, args) })
      else
        @jdl_includes << IncludeInfo.new(p ath, args)
      end
    end

    def executing_jdl? = @executing_jdl

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
    end

    NodeDefData = Data.define(:api_klass, :id, :src_loc, :args, :kwargs, :block)

    def register_node(api_klass, *args, **kwargs, &block)
      id = args.shift
      validate_id(id, :node)
      @node_defs << NodeDefData.new(api_klass, id, $last_call_location, args, kwargs, block)
    end

    def process_node_def(nd)
      if nd.api_klass == JDL::ProjectAPI
        proj_node = create_node(nd, no_api_klass: true) # structural node only, do not execute jdl
        @default_configs.each do |id|
          create_node(nd, parent: proj_node) do |node|
            node.get_attr(:config).set(id)
          end
        end
      else
        create_node(nd)
      end
    end

    def create_node(nd, parent: @top_level_node, no_api_klass: false)
      begin
        api_klass = no_api_klass ? nil : nd.api_klass
        node = Node.new(api_klass, nd.id, nd.src_loc, parent)
        yield node if block_given?
        node.eval_jdl(&nd.block) if api_klass && nd.block
        node.post_create
        return node
      rescue FrozenError => e
        msg = e.message.sub("frozen", "read only").capitalize_first
        msg.sub!(/:.*?$/, ".") if !mruby? # mruby does not inspect the value
        JABA.error(msg, backtrace: e.backtrace, want_backtrace: false)
      end
    end

    def log(msg, severity = :INFO, section: false)
      return if !@log_msgs
      if section
        max_width = 130
        n = ((max_width - msg.size) / 2).round
        if n > 2
          msg = "#{"=" * n} #{msg} #{"=" * n}"
        end
      end
      @log_msgs << "#{severity} #{msg}"
    end

    def term_log
      return if !@log_msgs || temp_dir.nil?
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
      msg = if jdl_bt.empty?
          "Warning: #{msg}"
        else
          make_error_info(msg, jdl_bt).message
        end
      if !@warning_lookup.has_key?(msg)
        log(msg, :WARN)
        @warnings << msg
      else
        @warning_lookup[msg] = true
      end
      nil
    end

    def get_jdl_backtrace(callstack)
      # Extract any lines in the callstack that contain references to definition source files.
      #
      jdl_bt = callstack.select { |c| @jdl_files.any? { |sf| c.include?(sf) } }

      # remove the unwanted ':in ...' suffix from user level definition errors
      #
      jdl_bt.map! { |l| l.clean_backtrace }

      # Can contain unhelpful duplicates due to loops, make unique.
      #
      jdl_bt.uniq!
      jdl_bt
    end

    ErrorInfo = Data.define(:message, :full_message, :file, :line)

    def make_error_info(msg, backtrace, exception: nil, want_err_line: true)
      m = String.new
      case exception
      when nil
        err_line = backtrace[0]
        m << "Warning"
      when ScriptError
        # With ruby ScriptErrors there is no useful callstack. The error location is in the msg itself.
        #
        err_line = msg
        if mruby? # mruby syntax errors need cleaning
          err_line.sub!("file ", "")
          err_line.sub!(" line ", ":")
        end

        # Delete ruby's way of reporting syntax errors in favour of our own
        #
        msg = msg.sub(/^.* syntax error, /, "")
        m << "Syntax error"
      else
        err_line = backtrace[0]
        m << "Error"
      end

      # Extract file and line information from the error line.
      #
      if want_err_line && err_line =~ /^(.+):(\d+)/
        file, line = $1, $2.to_i
        m << " at"
        m << " #{file.basename}:#{line}"
      end
      m << ": #{msg}"
      m.ensure_end_with!(".") if m =~ /[a-zA-Z0-9']$/

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

    def include_shared(id)
    end

    def in_attr_default_block? = !@attr_default_read_stack.empty?
    def outer_default_attr_read = @attr_default_read_stack.first

    def execute_attr_default_block(attr)
      @attr_default_read_stack.push(attr)
      result = nil
      attr.node.make_read_only do # default blocks should not attempt to set another attribute
        result = attr.node.eval_jdl(&attr.attr_def.get_default)
      end
      @attr_default_read_stack.pop
      result
    end

    # TODO: move to jrf
    def profile(enabled)
      if !enabled
        yield
        return
      end

      begin
        require "ruby-prof"
      rescue LoadError
        JABA.error("ruby-prof gem is required to run with --profile. Could not be loaded.", want_backtrace: false)
      end

      puts "Invoking ruby-prof..."
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
  end
end
