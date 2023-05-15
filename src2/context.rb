module JABA
  @@context = nil
  def self.set_context(c) = @@context = c
  def self.context = @@context

  @@running_tests = false
  def self.running_tests! = @@running_tests = true
  def self.running_tests? = @@running_tests

  def self.error(msg, caller_step_back: 2, **kwargs) = JABA.context.error(msg, caller_step_back: caller_step_back, **kwargs)
  def self.warn(msg, caller_step_back: 2, **kwargs) = JABA.context.warn(msg, caller_step_back: caller_step_back, **kwargs)
  def self.log(...) = JABA.context.log(...)

  class Context
    @@core_api_builder = nil

    def initialize(&block)
      JABA.set_context(self)
      @warnings = []
      @warning_lookup = {}
      @log_msgs = JABA.running_tests? ? nil : [] # Disable logging when running tests
      @input_block = block
      @input = Input.new
      @input.instance_variable_set(:@build_root, nil)
      @input.instance_variable_set(:@src_root, nil)
      @input.instance_variable_set(:@definitions, nil)
      @input.instance_variable_set(:@global_attrs_from_cmdline, {})
      @input.instance_variable_set(:@want_exceptions, false)
      @output = { warnings: @warnings, error: nil }
      @invoking_dir = Dir.getwd.freeze
      @src_root = @build_root = @temp_dir = nil
      @file_manager = FileManager.new
      @jdl_includes = []
      @jdl_file_lookup = {}
      @node_defs = []
      @shared_lookup = {}
      @executing_jdl = false
      @attr_def_block_stack = []
      @projects = []
    end

    def input = @input
    def output = @output
    def invoking_dir = @invoking_dir
    def src_root = @src_root
    def build_root = @build_root
    def temp_dir = @temp_dir
    def file_manager = @file_manager
    def top_level_node = @top_level_node

    def execute
      begin
        profile(input.profile?) do
          run
        end
      rescue JabaError => e
        raise e if input.want_exceptions?
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

      if @@core_api_builder.nil?
        @@core_api_builder = JDLBuilder.new
      end
      @jdl = if !JABA.current_api_blocks.empty?
          JDLBuilder.new(JABA.current_api_blocks)
        else
          @@core_api_builder
        end

      init_root_paths

      tld = NodeDefData.new(@jdl.top_level_node_def, "top_level", nil, nil, nil)
      create_node(tld, parent: nil) do |n|
        n.add_attrs(@jdl.top_level_node_def.attr_defs)
        @top_level_node = n
        @output[:root] = n
        @top_level_api_obj = @jdl.top_level_api_class.new(n)
        set_top_level_attrs_from_cmdline
        @executing_jdl = true
        load_jaba_files
      end

      @node_defs.each do |nd|
        process_node_def(nd)
      end

      @executing_jdl = false

      @top_level_node.visit do |n|
        n.attributes.each do |a|
          a.process_flags
        end
      end

      @projects.each do |p|
        p.process
        p.generate
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

    def set_top_level_attrs_from_cmdline
      input.global_attrs_from_cmdline&.each do |name, values|
        values = Array(values)

        attr = @top_level_node.get_attr(name.to_s, fail_if_not_found: false)
        if attr.nil?
          JABA.error("'#{name}' top level attribute not defined", want_backtrace: false)
        end

        attr_def = attr.attr_def
        type = attr_def.attr_type
        case attr_def.variant
        when :single
          if values.size > 1
            JABA.error("'#{name}' attribute only expects one value but #{values.inspect} provided", want_backtrace: false)
          end
          value = type.value_from_cmdline(values[0], attr_def)
          if attr.type_id == :file || attr.type_id == :dir
            value = value.to_absolute(base: invoking_dir, clean: true) # TODO: need to do this for array/hash elems too
          end
          attr.set(value)
        when :array
          if values.empty?
            JABA.error("'#{name}' array attribute requires one or more values", want_backtrace: false)
          end
          values = values.map { |v| type.value_from_cmdline(v, attr_def) }
          attr.set(values)
        when :hash
          if values.empty? || values.size % 2 != 0
            JABA.error("'#{name}' hash attribute requires one or more pairs of values", want_backtrace: false)
          end
          key_type = attr.attr_def.key_type
          values.each_slice(2) do |kv|
            key = key_type.value_from_cmdline(kv[0], attr_def)
            value = type.value_from_cmdline(kv[1], attr_def)
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
      if input.definitions
        execute_jdl(&input.definitions)
      end

      # Process include directives, accounting for included files including other files.
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
      begin
        if str
          @top_level_api_obj.instance_eval(str, file)
        elsif file
          log "Executing #{file}"
          @top_level_api_obj.instance_eval(file_manager.read(file), file)
        end
        if block_given?
          @top_level_api_obj.instance_exec(*args, &block)
        end
      rescue ScriptError => e # script errors don't have a backtrace
        JABA.error(e.message, type: :script_error)
      rescue NameError => e
        JABA.error(e.message, line: e.backtrace[0])
      end
    end

    NodeDefData = Data.define(:node_def, :id, :src_loc, :kwargs, :block)

    # Nodes are registered in the first pass and then subsequently processed. They
    # cannot be processed immediately because top level attributes need to be fully
    # initialised first
    #
    def register_node(node_def, *args, **kwargs, &block)
      id = args.shift
      validate_id(id, :node)
      JABA.error("Only a single id argument can be passed to '#{node_def.name.inspect_unquoted}'") if !args.empty?
      @node_defs << NodeDefData.new(node_def, id, $last_call_location, kwargs, block)
    end

    def process_node_def(nd)
      parent = @top_level_node
      if !nd.node_def.option_attr_defs.empty? || !@jdl.common_attr_node_def.option_attr_defs.empty?
        parent = create_node(nd, parent: parent, eval_jdl: false) do |node|
          node.add_attrs(@jdl.common_attr_node_def.option_attr_defs)
          node.add_attrs(nd.node_def.option_attr_defs)
          node.get_attr(:id).set(nd.id)
          nd.kwargs.each do |attr_name, val|
            node.get_attr(attr_name).set(val)
          end
        end
      end
      if nd.node_def.name == "target"
        if @target_attr_defs.nil?
          @target_attr_defs = []
          @config_attr_defs = []
          nd.node_def.attr_defs.each do |ad|
            if ad.has_flag?(:per_target)
              @target_attr_defs << ad
            elsif ad.has_flag?(:per_config)
              @config_attr_defs << ad
            else
              ad.definition_error("must be flagged with either :per_target or :per_config")
            end
          end
          @target_attrs_ignore = AttributeLookupHash.new.tap do |h|
            @target_attr_defs.each{|ta| h[ta.name] = true}
          end
          @config_attrs_ignore = AttributeLookupHash.new.tap do |h|
            @config_attr_defs.each{|ca| h[ca.name] = true}
          end
        end
        target_node = create_node(nd, parent: parent) do |node|
          node.add_attrs(@jdl.common_attr_node_def.attr_defs)
          node.add_attrs(@target_attr_defs)
          node.ignore_attrs(set: @config_attrs_ignore, get: @config_attrs_ignore)
        end
        configs = target_node[:configs]
        configs.each do |id|
          create_node(nd, parent: target_node) do |node|
            node.add_attrs(@config_attr_defs)
            node.ignore_attrs(set: @target_attrs_ignore)
            node.get_attr(:config).set(id, __force: true)
          end
        end
        @target_node_to_vcxproj ||= {}
        vcxproj = Vcxproj.new(target_node)
        @target_node_to_vcxproj[target_node] = vcxproj
        @projects << vcxproj
      else
        create_node(nd, parent: parent) do |node|
          node.add_attrs(@jdl.common_attr_node_def.attr_defs)
          node.add_attrs(nd.node_def.attr_defs)
        end
      end
    end

    def create_node(nd, parent:, eval_jdl: true)
      begin
        node = Node.new(nd.node_def, nd.id, nd.src_loc, parent)
        yield node if block_given?
        node.eval_jdl(&nd.block) if nd.block && eval_jdl
        node.post_create
        return node
      rescue FrozenError => e
        msg = e.message.sub("frozen", "read only").capitalize_first
        msg.sub!(/:.*?$/, ".") if !mruby? # mruby does not inspect the value
        JABA.error(msg, line: e.backtrace[0])
      end
    end

    def validate_id(id, what)
      if !(id.symbol? || id.string?) || id !~ /^[a-zA-Z0-9_\-.|]+$/
        msg = if id.nil?
            "'#{what}' requires an id"
          else
            "'#{id}' is an invalid id"
          end
        msg << ". Must be an alphanumeric string or symbol (-_. permitted), eg :my_id, 'my-id', 'my.id'"
        JABA.error(msg, line: $last_call_location)
      end
    end

    def register_shared(id, block)
      if lookup_shared(id, fail_if_not_found: false)
        JABA.error("shared definition '#{id.inspect_unquoted}' multiply defined", line: $last_call_location)
      end
      @shared_lookup[id] = block
    end

    def lookup_shared(id, fail_if_not_found: true)
      s = @shared_lookup[id]
      if s.nil? && fail_if_not_found
        JABA.error("shared definition '#{id.inspect_unquoted}' not defined", line: $last_call_location)
      end
      s
    end

    def in_attr_def_block? = !@attr_def_block_stack.empty?
    def outer_attr_def_block_attr = @attr_def_block_stack.first

    def execute_attr_def_block(attr, block)
      @attr_def_block_stack.push(attr)
      result = nil
      attr.node.make_read_only do # attr def blocks should only read attributes not set them
        result = attr.node.eval_jdl(&block)
      end
      @attr_def_block_stack.pop
      result
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

    def error(msg, line: nil, type: :error, caller_step_back: 1, errobj: nil, want_err_line: true, want_backtrace: true)
      if errobj
        line = if errobj.proc?
            "#{errobj.source_location[0]}:#{errobj.source_location[1]}"
          else
            errobj.src_loc
          end
      end
      bt = if line
          want_backtrace = false
          Array(line)
        else
          caller(caller_step_back)
        end
      info = make_error_info(msg, bt, type: type, want_err_line: want_err_line)
      log info.full_message, :ERROR
      output[:error] = want_backtrace ? info.full_message : info.message
      e = JabaError.new(info.message)
      e.instance_variable_set(:@raw_message, msg) # For use when exeception wrapped
      e.set_backtrace(bt)
      raise e
    end

    def warn(msg, line: nil, caller_step_back: 0, want_warn_line: true)
      bt = if line
          Array(line)
        else
          caller(caller_step_back)
        end
      msg = make_error_info(msg, bt, type: :warn, want_err_line: want_warn_line).message
      if !@warning_lookup.has_key?(msg)
        log(msg, :WARN)
        @warnings << msg
      else
        @warning_lookup[msg] = true
      end
      nil
    end

    ErrorInfo = Data.define(:message, :full_message, :file, :line)

    def make_error_info(msg, backtrace, type:, want_err_line: true)
      m = String.new
      case type
      when :warn
        err_line = backtrace[0]
        m << "Warning"
      when :script_error
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
