module JABA
  @@context = nil
  def self.set_context(c) = @@context = c
  def self.context = @@context

  @@running_tests = false
  def self.running_tests! = @@running_tests = true
  def self.running_tests? = @@running_tests

  def self.error(msg, caller_step_back: 2, **kwargs)
    ctxt = JABA.context
    if ctxt
      ctxt.error(msg, caller_step_back: caller_step_back, **kwargs)
    else
      raise JabaError, msg
    end
  end

  def self.warn(msg, caller_step_back: 2, **kwargs)
    ctxt = JABA.context
    if ctxt
      ctxt.warn(msg, caller_step_back: caller_step_back, **kwargs)
    else
      puts "Warning: #{msg}"
    end
  end

  class Context
    @@attr_types = []
    @@attr_type_lookup = {}
    @@attr_flags = []
    @@attr_flag_lookup = {}

    @@standard_jdl_builder = nil
    @@core_jdl_block = nil
    @@standard_jdl_blocks = []
    @@overridden_jdl_blocks = [] # used in testing

    def self.all_attr_type_names = @@attr_types.map { |at| at.name }
    def self.lookup_attr_type(name, fail_if_not_found: true)
      at = @@attr_type_lookup[name]
      if at.nil? && fail_if_not_found
        JABA.error("'#{name.inspect_unquoted}' attribute type not found")
      end
      at
    end

    def self.all_attr_flag_names = @@attr_flags.map { |at| at.name }
    def self.lookup_attr_flag(name, fail_if_not_found: true)
      af = @@attr_flag_lookup[name]
      if af.nil? && fail_if_not_found
        JABA.error("'#{name.inspect_unquoted}' attribute flag not found")
      end
      af
    end

    def self.define_core_jdl(&block)
      define_jdl(&block)
      @@core_jdl_block = block
    end

    def self.define_jdl(&block)
      raise "block required" if !block
      @@standard_jdl_blocks << block
    end

    def self.standard_jdl_blocks = @@standard_jdl_blocks

    def self.define_jdl_override(level:, &block)
      raise "block required" if !block
      @@overridden_jdl_blocks.clear
      case level
      when :blank
        # nothing
      when :core
        @@overridden_jdl_blocks << @@core_jdl_block
      when :full
        @@overridden_jdl_blocks.concat(@@standard_jdl_blocks)
      else
        raise "Invalid jdl override level '#{level.inspect_unquoted}'"
      end
      @@overridden_jdl_blocks << block
    end
    def self.restore_standard_jdl = @@overridden_jdl_blocks.clear # Used by unit tests

    def self.init
      JABA.constants(false).each do |c|
        case c
        when /^AttributeType./
          klass = JABA.const_get(c)
          at = klass.new
          @@attr_types << at
          @@attr_type_lookup[at.name] = at
        when /^AttributeFlag./
          klass = JABA.const_get(c)
          af = klass.new
          @@attr_flags << af
          @@attr_flag_lookup[af.name] = af
        end
      end
      @@attr_types.sort_by!(&:name)
      @@attr_flags.sort_by!(&:name)
      @@standard_jdl_builder = JDLBuilder.new
    end

    def initialize(&block)
      JABA.set_context(self)
      @warnings = []
      @warning_lookup = {}
      @input_block = block
      @input = Input.new
      @input.instance_variable_set(:@src_root, nil)
      @input.instance_variable_set(:@definitions, nil)
      @input.instance_variable_set(:@global_attrs_from_cmdline, {})
      @input.instance_variable_set(:@want_exceptions, false)
      @output = { warnings: @warnings, error: nil }
      @invoking_dir = Dir.getwd.freeze
      @src_root = nil
      @src_root_dir = nil
      @file_manager = FileManager.new
      @jdl_file_lookup = {}
      @node_defs = []
      @shared_lookup = {}
      @executing_jdl = 0
      @attr_def_block_stack = []
      @target_defaults_global = []
      @target_defaults_file = {}
      @target_nodes = []
      @target_lookup = KeyToSHash.new # target id to target node
      @projects = []
      @project_lookup = {} # target node to project
    end

    def input = @input
    def output = @output
    def invoking_dir = @invoking_dir
    def src_root_dir = @src_root_dir
    def file_manager = @file_manager
    def root_node = @root_node
    def begin_jdl = @executing_jdl += 1
    def end_jdl = @executing_jdl -= 1
    def executing_jdl? = @executing_jdl > 0
    def jdl_builder = @jdl

    def execute
      begin
        profile(input.profile?) do
          run
        end
      rescue JabaError => e
        raise e if input.want_exceptions?
      end
    end

    def run
      duration = milli_timer do
        do_run
      end

      file_manager.include_untracked # Include all generated files for the purpose of reporting back to the user

      generated = file_manager.generated.map { |f| f.relative_path_from(@src_root_dir) }
      added = file_manager.added.map { |f| f.relative_path_from(@src_root_dir) }.sort_no_case!
      modified = file_manager.modified.map { |f| f.relative_path_from(@src_root_dir) }.sort_no_case!
      unchanged = file_manager.unchanged.map { |f| f.relative_path_from(@src_root_dir) }.sort_no_case!

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

      output[:added] = added
      output[:modified] = modified
      output[:unchanged] = unchanged
      output[:summary] = summary
    end

    def do_run
      @input_block&.call(input)

      @jdl = if !@@overridden_jdl_blocks.empty?
          JDLBuilder.new(@@overridden_jdl_blocks)
        else
          @@standard_jdl_builder
        end

      init_src_root

      tld = NodeDefData.new(@jdl.top_level_node_def, "root", nil, nil, nil)
      create_node(tld, "root", parent: nil) do |n|
        n.add_attrs(@jdl.top_level_node_def.attr_defs)
        @root_node = n
        @output[:root] = n
        set_top_level_attrs_from_cmdline
        # Definitions can be provided in a block form or source form but not both
        if input.definitions
          @root_node.eval_jdl(&input.definitions)
        else
          process_load_path(@src_root, fail_if_empty: true)
        end
      end

      # Split default blocks into global and per-file
      #
      @root_node.get_attr(:defaults, fail_if_not_found: false)&.each do |elem|
        # retrieve and then delete scope option as it has done its work should not be interpreted
        # as a target node option like the rest of the options
        scope = elem.option_value(:scope, pop: true)
        case scope
        when :global
          @target_defaults_global << elem
        when :file
          file = elem.src_loc.src_loc_info[0]
          @target_defaults_file.push_value(file, elem)
        else
          JABA.error("Unrecognised scope '#{scope.inspect_unquoted}'")
        end
      end

      @node_defs.each do |nd|
        process_node_def(nd)
      end

      @target_nodes.each do |n|
        n.get_attr(:deps).map_value! do |dep_id|
          lookup_target(dep_id)
        end
      end

      @target_nodes.sort_topological! do |n, &b|
        n[:deps].each(&b)
      end

      @target_nodes.reverse_each do |n|
        n.process_deps
      end

      @target_nodes.each do |n|
        n.get_attr(:deps).delete_if do |d|
          dep_node = d.value
          dep_node.virtual?
        end
      end

      @root_node.visit do |n|
        n.attributes.each do |attr|
          attr.visit_elem do |elem|
            :delete if elem.has_flag_option?(:export_only)
          end
          attr.process_flags
        end
      end

      @projects.each(&:generate)
    end

    def init_src_root
      if (input.definitions.nil? && input.src_root.nil?) || (!input.definitions.nil? && !input.src_root.nil?)
        JABA.error("either src_root or definitions block must be provided but not both")
      end

      # src_root could be a .jaba file or a directory containing .jaba files
      @src_root = if input.definitions
          input.definitions.source_location[0].cleanpath
        else
          input.src_root.to_absolute(base: invoking_dir, clean: true)
        end
      @src_root.freeze

      if !File.exist?(@src_root)
        JABA.error("source root '#{@src_root}' does not exist", want_backtrace: false)
      end

      @src_root_dir = File.directory?(@src_root) ? @src_root : @src_root.parent_path
      @src_root_dir.freeze
    end

    def set_top_level_attrs_from_cmdline
      input.global_attrs_from_cmdline&.each do |name, values|
        values = Array(values)

        attr = @root_node.get_attr(name.to_s, fail_if_not_found: false)
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
            JABA.error(msg, want_backtrace: false, want_err_line: false)
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

      str = @file_manager.read(f)
      @root_node.eval_jdl_str(str, f)
    end

    def process_include(path)
      if path.nil?
        JABA.error("include requires a path")
      end
      if !path.absolute_path?
        path = "#{$last_call_location.src_loc_info[0].parent_path}/#{path}"
      end
      if !File.directory?(path)
        path = path.ensure_end_with(".jaba")
      end
      if path.wildcard?
        @file_manager.glob_files(path).each do |p|
          process_load_path(p)
        end
      else
        process_load_path(path)
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
      is_target = nd.node_def.name == "target"
      klass = is_target ? TargetNode : Node

      node = create_node(nd, nd.id, klass: klass, parent: @root_node, eval_jdl: !is_target) do |n|
        n.add_attrs(@jdl.common_attr_node_def.option_attr_defs)
        n.add_attrs(@jdl.common_attr_node_def.attr_defs)
        n.add_attrs(nd.node_def.option_attr_defs)
        n.add_attrs(nd.node_def.attr_defs)

        id_attr = n.get_attr(:id, fail_if_not_found: false)
        if id_attr
          id_attr.set(nd.id)
        end

        if is_target
          @target_nodes << n
          @target_lookup[nd.id] = n

          # Set options that were passed into default block(s)
          #
          each_default(n) do |a|
            a.value_options.each do |name, oattr|
              a = n.get_attr(name)
              a.set_last_call_location(n.src_loc)
              a.set(oattr.value)
            end
          end
        end

        # Set options that were passed into actual definition
        #
        nd.kwargs.each do |name, val|
          a = n.get_attr(name)
          a.set_last_call_location(n.src_loc)
          if !a.attr_def.has_flag?(:node_option)
            a.attr_error("#{a.describe} must be set in the definition body")
          end
          a.set(val)
        end

        # Check that all required options were passed in and make them read only from now on
        #
        n.attributes.each do |a|
          ad = a.attr_def
          if ad.has_flag?(:node_option)
            if ad.has_flag?(:required) && !a.set?
              JABA.error("#{n.describe} requires #{a.describe} to be passed in", errobj: n)
            end
            a.set_read_only
          end
        end
      end
      if is_target
        process_target(nd, node)
      end
    end

    def process_target(nd, target_node)
      target_node[:configs].each do |cfg_id|
        create_node(nd, cfg_id, parent: target_node) do |n|
          n.add_attrs(@jdl.common_attr_node_def.attr_defs)
          n.add_attrs(nd.node_def.attr_defs)
          n.get_attr(:config).set(cfg_id, __force: true)
          apply_defaults(n)
        end
      end

      target_node.attributes.each do |a|
        if a.attr_def.has_flag?(:per_target)
          target_node.pull_up(a)
        end
      end

      target_node.post_create

      if !target_node.virtual?
        vcxproj = Vcxproj.new(target_node)
        @projects << vcxproj
        @project_lookup[target_node] = vcxproj
      end
    end

    def create_node(nd, sibling_id, klass: Node, parent:, eval_jdl: true)
      begin
        node = klass.new
        node.init(nd.node_def, sibling_id, nd.src_loc, parent)
        yield node if block_given?
        if eval_jdl
          node.eval_jdl(&nd.block) if nd.block
          node.post_create
        end
        return node
      rescue FrozenError => e
        msg = e.message.sub("frozen", "read only").capitalize_first
        msg.sub!(/:.*?$/, ".") if !mruby? # mruby does not inspect the value
        JABA.error(msg, line: e.backtrace[0])
      end
    end

    def each_default(node, &block)
      @target_defaults_global.each(&block)
      @target_defaults_file[node.src_file]&.each(&block)
    end

    def apply_defaults(node)
      each_default(node) do |attr|
        block = attr.value
        node.eval_jdl(&block)
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

    def lookup_target(id, fail_if_not_found: true)
      t = @target_lookup[id]
      JABA.error("'#{id.inspect_unquoted}' not found") if t.nil? && fail_if_not_found
      t
    end

    def lookup_project(target_node, fail_if_not_found: true)
      p = @project_lookup[target_node]
      JABA.error("#{target_node.describe} not found") if p.nil? && fail_if_not_found
      p
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
      return block if !block.proc?
      @attr_def_block_stack.push(attr)
      result = nil
      attr.node.make_read_only do # attr def blocks should only read attributes not set them
        result = attr.node.eval_jdl(called_from_jdl: false, &block)
      end
      @attr_def_block_stack.pop
      result
    end

    def error(msg, line: nil, type: :error, caller_step_back: 1, errobj: nil, want_err_line: true, want_backtrace: true)
      if errobj
        line = if errobj.proc?
            "#{errobj.source_location[0]}:#{errobj.source_location[1]}"
          else
            errobj.src_loc
          end
      elsif line.nil? && executing_jdl?
        line = $last_call_location
      end

      bt = if line
          want_backtrace = false
          Array(line)
        else
          caller(caller_step_back)
        end
      info = make_error_info(msg, bt, type: type, want_err_line: want_err_line)
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
        @warnings << msg
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
      file = "#{invoking_dir}/jaba.profile"
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
