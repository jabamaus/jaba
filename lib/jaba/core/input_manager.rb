# frozen_string_literal: true

##
#
module JABA

  using JABACoreExt

  ##
  #
  class InputManager

    attr_reader :input

    ##
    #
    def initialize(services)
      @services = services
      @input = services.input
      @options = []
      @cmds = []

      # General non-cmd-specific options
      #
      register_option('--help', help: 'Show help', phase: 2)
      register_option('--dry-run', help: 'Perform a dry run', type: :flag, var: :dry_run)
      register_option('--profile', help: 'Profiles with ruby-prof', type: :flag, var: :profile, dev_option: true)
      register_option('--barebones', help: 'Loads minimal modules', type: :flag, var: :barebones, dev_option: true)

      @default_cmd = register_cmd(:gen, help: 'Regenerate buildsystem')
      register_option('--src-root', short: '-S', help: 'Set src root', type: :value, var: :src_root, cmd: :gen)
      register_option('--build-root', short: '-B', help: 'Set build root', type: :value, var: :build_root, cmd: :gen)
      register_option('--define', short: '-D', help: 'Set global attribute value', phase: 3, cmd: :gen)
      register_option('--dump-state', help: 'Dump state to json for debugging', type: :flag, var: :dump_state, cmd: :gen)
      
      register_cmd(:build, help: 'Execute build')
      register_cmd(:clean, help: 'Clean build')
      register_cmd(:help, help: 'Open jaba web help')
    end

    ##
    #
    def register_cmd(id, help:, dev_cmd: false)
      JABA.error("cmd id must be a symbol") if !id.symbol?
      if id !~ /^[a-zA-Z0-9\-]+$/
        JABA.error("Invalid cmd id '#{id}' specified. Can only contain [a-zA-Z0-9-]")
      end
      c = OpenStruct.new
      c.id = id
      c.help = help
      c.options = []
      c.dev_cmd = dev_cmd
      @cmds << c
      c
    end

    ##
    #
    def register_option(long, short: nil, help:, type: nil, var: nil, dev_option: false, phase: 1, cmd: nil)
      if long !~ /^--[a-zA-Z0-9\-]+$/
        JABA.error("Invalid long option format '#{long}' specified. Must be of form --my-long-option")
      end
      if short && short !~ /^-[a-zA-Z]$/
        JABA.error("Invalid short option format '#{short}' specified. Must be of form -O")
      end
      
      o = OpenStruct.new
      o.long = long
      o.short = short
      o.help = help
      o.type = type
      o.inst_var = var ? "@#{var}" : nil
      o.dev_option = dev_option
      o.phase = phase
      o.cmd = cmd
      o.describe = short ? "#{short} [#{long}]" : long
      
      if cmd
        c = get_cmd(cmd, fail_if_not_found: true)
        c.options << o
      end

      @options << o

      if var
        if !@input.respond_to?(var)
          @input.define_singleton_method(var) do
            instance_variable_get(o.inst_var)
          end
        end
        val = case type
        when :flag
          false
        when :value
          @input.instance_variable_get(o.inst_var)
        when :array
          []
        else
          JABA.error("Unhandled type '#{type}'")
        end
        @input.instance_variable_set(o.inst_var, val)
      end
      o
    end

    ##
    #
    def process(phase:)
      process_cmd_line(phase)
    end

    ##
    #
    def cmd_specified?(id)
      get_cmd(id, fail_if_not_found: true) # Validate cmd exists
      input.instance_variable_get(:@cmd) == id
    end

    ##
    #
    def get_cmd(id, fail_if_not_found: true)
      c = @cmds.find{|c| c.id == id}
      if !c && fail_if_not_found
        JABA.error("#{id} command not recognised")
      end
      c
    end

    ##
    #
    def get_option(arg)
      @options.find do |o|
        arg == o.long || arg == o.short
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
      JABA.error(msg, want_backtrace: false)
    end

    ##
    #
    def process_cmd_line(phase)
      globals_node = @services.globals_node
      input = @input
      im = self
      default_cmd = @default_cmd

      # Take a copy because cmd line is parsed twice
      #
      argv = Array(input.argv).dup

      FSM.new(events: [:process_arg]) do
        state :want_cmd do
          on_process_arg do |arg|
            cmd = nil
            if arg.start_with?('-')
              cmd = default_cmd
              argv.unshift(arg)
            else
              cmd = im.get_cmd(arg.to_sym, fail_if_not_found: false)
              if cmd.nil?
                im.usage_error("#{arg} command not recognised")
              end
            end
            input.instance_variable_set(:@cmd, cmd.id)
            goto :want_option
          end
        end
        state :want_option do
          on_process_arg do |arg|
            opt = im.get_option(arg)

            if opt.nil?
              im.usage_error("#{arg} option not recognised")
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
              goto :want_option
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
              goto :want_option
            else
              @val = arg
              goto :want_option
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
              goto :want_option
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
              @value.to_absolute!(base: @services.invoking_dir, clean: true) # TODO: need to do this for array/hash elems too
            end
            @attr.set(@value)
          end
          on_process_arg do |arg|
            if im.option_defined?(arg)
              argv.unshift(arg)
            else
              @value = @type.from_string(arg)
            end
            goto :want_option
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

            # Normal jaba array behaviour is always to concat to the existing value but when setting from the command
            # line the behaviour is to replace the existing value.
            #
            @attr.clear
            @attr.set(@elems)
          end
          on_process_arg do |arg|
            if im.option_defined?(arg)
              argv.unshift(arg)
              goto :want_option
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
                goto :want_option
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
            break if arg == '--'
            send_event(:process_arg, arg)
          end
        end
      end
    end

    ##
    #
    def show_help
      @max_width = 120
      w = StringWriter.new
      w << "Jaba build system generator v#{VERSION}"
      w << "Copyright (C) 2020-#{Time.now.year} James French"
      w << "Built on ruby #{RUBY_VERSION}p#{RUBY_PATCHLEVEL} #{RUBY_RELEASE_DATE} [#{RUBY_PLATFORM}] #{RUBY_COPYRIGHT.sub('ruby', '')}"
      w << ""
      if @services.src_root_valid?
        w << "Current src_root: #{@input.src_root}"
        w << ""
      end
      w << "Usage:"
      w << ""
      w << "  jaba cmd [options]"
      w << ""
      w << "Commands:"
      w << ""
      
      @cmds.each do |c|
        next if c.dev_cmd
        print_cmd_help(c, w)
        w << ""
      end

      w << "General options:"
      w << ""
      print_cmd_help(nil, w)

      w << ""

      puts w
      exit!
    end

    ##
    #
    def print_cmd_help(cmd, w)
      opts = []
      items = []
      help_items = []
      option_indent = 4

      if cmd
        opts.concat(cmd.options.select{|o| !o.dev_option})
        cmd_str = "  #{cmd.id}"
        if cmd == @default_cmd
          cmd_str << ' (default)'
        end
        items << cmd_str
        help_items << cmd
      else
        opts.concat(@options.select{|o| !o.cmd && !o.dev_option && o.long != '--help'})
        option_indent = 2
      end
      
      items.concat(opts.map{|o| "#{' ' * option_indent}#{o.describe}"})
      help_items.concat(opts)

      max_len = items.map{|i| i.length}.max
      help_start = max_len + 2

      items.each_with_index do |i, index|
        hi = help_items[index]
        w << "#{i}#{' ' * (max_len - i.size)}  #{hi.help.wrap(@max_width, prefix: (' ' * help_start), trim_leading_prefix: true)}"
      end
    end

  end

end
