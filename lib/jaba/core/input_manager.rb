# frozen_string_literal: true

##
#
module JABA

  using JABACoreExt

  ##
  #
  class InputManager

    Cmd = Struct.new(:name, :options)
    CmdLineOption = Struct.new(:long, :short, :spec, :help, :type, :inst_var, :dev_option, :phase, :cmd)

    attr_reader :input

    ##
    #
    def initialize(services)
      @services = services
      @options = []
      @commands = []

      @input = Input.new
      @input.instance_variable_set(:@dest_root, JABA.cwd)
      @input.instance_variable_set(:@argv, ARGV)
      @input.instance_variable_set(:@definitions, [])
      @input.instance_variable_set(:@barebones, false)
      
      register_options
    end

    ##
    #
    def register_cmd(name)
      c = Cmd.new
      c.name = name
      c.options = []
      @commands << c
    end

    ##
    #
    def register_options
      register_cmd(:gen)
      register_cmd(:build)
      register_cmd(:clean)
      register_cmd(:genref)

      register_option('--help', help: 'Show help', phase: 2)

      register_option('--src-root', short: '-S', help: 'Set src root', type: :value, var: :src_root, cmd: :gen)
      register_option('--define', short: '-D', help: 'Set global attribute value', phase: 2, cmd: :gen)
      
      register_option('--dry-run', help: 'Perform a dry run', type: :flag, var: :dry_run)
      register_option('--gen-ref', help: 'Generates reference doc', type: :flag, var: :generate_reference_doc, dev_option: true, phase: 2)
      register_option('--profile', help: 'Profiles with ruby-prof', type: :flag, var: :profile, dev_option: true)
    end

    ##
    #
    def register_option(long, short: nil, help:, type: nil, var: nil, dev_option: false, phase: 1, cmd: nil)
      if long !~ /^--[a-zA-Z0-9\-]+$/
        @services.jaba_error("Invalid long option format '#{long}' specified. Must be of form --my-long-option")
      end
      if short && short !~ /^-[a-zA-Z]$/
        @services.jaba_error("Invalid short option format '#{short}' specified. Must be of form -O")
      end
      
      o = CmdLineOption.new
      o.long = long
      o.short = short
      o.help = help
      o.type = type
      o.inst_var = var ? "@#{var}" : nil
      o.dev_option = dev_option
      o.phase = phase
      o.cmd = cmd
      o.spec = if short
        "#{short} [#{long}]"
      else
        long
      end

      o.define_singleton_method :describe do
        o.spec
      end
      
      if cmd
        c = get_cmd(cmd)
        c.options << o
      end

      @options << o

      if var
        @input.define_singleton_method(var) do
          instance_variable_get(o.inst_var)
        end
        val = case type
        when :flag
          false
        when :value
          nil
        when :array
          []
        else
          raise "Unhandled type '#{type}'"
        end
        @input.instance_variable_set(o.inst_var, val)
      end
    end

    ##
    #
    def get_cmd(name)
      c = @commands.find{|a| a.name == name}
      if !c
        @services.jaba_error("'#{name}' command not defined")
      end
      c
    end

    ##
    #
    def get_option(arg)
      @options.find do |o|
        arg.start_with?(o.long) || (o.short && arg.start_with?(o.short))
      end
    end

    ##
    #
    def option_defined?(arg)
      get_option(arg) != nil
    end

    ##
    #
    def usage_error(msg)
      raise CommandLineUsageError, msg
    end

    ##
    #
    def process(phase:)
      process_cmd_line(phase)

      # TODO: automatically patch in new attrs
      if phase == 2
        if !JABA.running_tests?
          # Only create config.jaba for out of src builds
          #
          if input.src_root
            config_file = JABA.config_file
            if !File.exist?(config_file)
              @services.globals_node.allow_set_read_only_attrs do
                @services.globals.src_root input.src_root
              end
              make_jaba_config(config_file)
            end
          end
        end
      end
    end

    ##
    #
    def process_cmd_line(phase)
      globals_node = @services.globals_node
      input = @input
      im = self

      # Take a copy because cmd line is parsed twice
      #
      argv = Array(input.argv).dup

      FSM.new(events: [:process_arg]) do
        state :default do
          on_process_arg do |arg|
            opt = im.get_option(arg)

            if opt.nil?
              # Phase 2 options may not have had the chance to register yet so ignore unkown options
              #
              if phase == 1
                goto :ignore
                next
              else
                im.usage_error("#{arg} option not recognised")
              end
            end

            # See if value was tacked on the end. If so, split and start again
            #
            if arg =~ /^(#{opt.long})(.+)$/ || (opt.short && arg =~ /^(#{opt.short})(.+)$/)
              argv.unshift(Regexp.last_match(2))
              argv.unshift(Regexp.last_match(1))
              next
            end

            if phase != opt.phase
              goto :ignore
              next
            end

            case opt.long
            when '--help'
              im.show_help
            when '--define'
              goto :global_attr
            else
              case opt.type
              when :flag
                input.instance_variable_set(opt.inst_var, true)
              when :value
                goto :value, opt
              when :array
                goto :array, opt
              end
            end
          end
        end
        state :ignore do
          on_process_arg do |arg|
            if im.option_defined?(arg)
              argv.unshift(arg)
              goto :default
            end
          end
        end
        state :value do
          on_enter do |opt|
            @opt = opt
            @val = nil
          end
          on_exit do
            if @val.nil?
              im.usage_error("#{@opt.describe} expects a value")
            end
            input.instance_variable_set(@opt.inst_var, @val)
          end
          on_process_arg do |arg|
            if im.option_defined?(arg)
              argv.unshift(arg)
              goto :default
            else
              @val = arg
              goto :default
            end
          end
        end
        state :array do
          on_enter do |opt|
            @opt = opt
            @elems = []
          end
          on_exit do
            if @elems.empty?
              im.usage_error("#{@opt.describe} expects 1 or more values")
            end
            ary = input.instance_variable_get(@opt.inst_var)
            ary.concat(@elems)
          end
          on_process_arg do |arg|
            if im.option_defined?(arg)
              argv.unshift(arg)
              goto :default
            else
              @elems << arg
            end
          end
        end
        state :global_attr do
          on_enter do
            @attr = nil
          end
          on_exit do
            if @attr.nil?
              im.usage_error('No attribute name supplied')
            end
          end
          on_process_arg do |arg|
            @attr = globals_node.get_attr(arg.to_sym, fail_if_not_found: false)
            if !@attr
              im.usage_error("'#{arg}' attribute not defined in :globals type")
            end
            case @attr.attr_def.variant
            when :single
              goto :global_attr_single, @attr
            when :array
              goto :global_attr_array, @attr
            when :hash
              goto :global_attr_hash, @attr
            end
          end
        end
        state :global_attr_single do
          on_enter do |attr|
            @attr = attr
            @type = attr.attr_def.jaba_attr_type
            @value = nil
            if @attr.type_id == :bool
              @value = true
            end
          end
          on_exit do
            if @value.nil?
              im.usage_error("No value provided for '#{arg}'")
            end
            if @attr.type_id == :file || @attr.type_id == :dir
              @value = @value.to_absolute(clean: true)
            end
            @attr.set(@value)
          end
          on_process_arg do |arg|
            if im.option_defined?(arg)
              argv.unshift(arg)
            else
              @value = @type.from_string(arg)
            end
            goto :default
          end
        end
        state :global_attr_array do
          on_enter do |attr|
            @attr = attr
            @type = attr.attr_def.jaba_attr_type
            @elems = []
          end
          on_exit do
            if @elems.empty?
              im.usage_error("No values provided for '#{arg}'")
            end
            @attr.set(@elems)
          end
          on_process_arg do |arg|
            if im.option_defined?(arg)
              argv.unshift(arg)
              goto :default
            else
              val = @type.from_string(arg)
              @elems << val
            end
          end
        end
        state :global_attr_hash do
          on_enter do |attr|
            @attr = attr
            @key_type = attr.attr_def.jaba_attr_key_type
            @type = attr.attr_def.jaba_attr_type
            @key = nil
            @elems = {}
          end
          on_exit do
            @elems.each do |k, v|
              @attr.set(k, v)
            end
          end
          on_process_arg do |arg|
            if im.option_defined?(arg)
              if @elems.empty?
                im.usage_error("No valued provided for '#{arg}'")
              else
                argv.unshift(arg)
                goto :default
              end
            end
            if @key.nil?
              @key = @key_type.from_string(arg)
            else
              @elems[@key] = @type.from_string(arg)
              @key = nil
            end
          end
        end
        on_run do
          while !argv.empty?
            arg = argv.shift
            send_event(:process_arg, arg)
          end
        end
      end
    end

    ##
    #
    def make_jaba_config(config_file)
      file = @services.file_manager.new_file(config_file, track: false, eol: :native)
      w = file.writer

      @services.globals_node.visit_attr(top_level: true) do |attr, value|
        attr_def = attr.attr_def

        # TODO: include ref manual type docs, eg type, definition location etc
        comment = String.new("#{attr_def.title}. #{attr_def.notes.join("\n")}")
        comment.wrap!(130, prefix: '# ')

        w << "##"
        w << comment
        w << "#"
        if attr.hash?
          value.each do |k, v|
            w << "#{attr_def.defn_id} #{k.inspect}, #{v.inspect}"
          end
        else
          w << "#{attr_def.defn_id} #{value.inspect}"
        end
        w << ''
      end
      w.chomp!

      file.write
    end

    ##
    #
    def show_help
      @max_width = 120
      w = StringWriter.new
      w << "jaba v#{VERSION}"
      w << ""
      w << "Usage: jaba cmd [options]"
      w << ""
      w << "Commands:"
      w << ""
      
      @commands.each do |a|
        w << "  #{a.name}"
        opts = a.options.select{|o| !o.dev_option}
        print_options(w, 4, opts)
        w << ""
      end

      w << "General options:"
      w << ""
      opts = @options.select{|o| !o.cmd && !o.dev_option && o.long != '--help'}
      print_options(w, 2, opts)

      w << ""

      puts w
      exit
    end

    ##
    #
    def print_options(w, indent, opts)
      return if opts.empty?
      max_len = opts.map{|o| o.spec.length}.max
      help_start = max_len + indent + 2

      opts.each do |o|
        w << "#{' ' * indent}#{o.spec}#{' ' * (max_len - o.spec.size)}  #{o.help.wrap(130, prefix: (' ' * help_start), trim_leading_prefix: true)}"
      end
    end

  end

end
