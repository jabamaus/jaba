module JABA

  ##
  #
  class Cmd

    attr_reader :id
    attr_reader :help
    attr_reader :dev_only
    #attr_reader :options

    def initialize(id, help, dev_only, &block)
      @id = id
      @help = help
      @dev_only = dev_only
      @options = []
      yield self if block_given?
    end

    ##
    #
    def add_option(long, short: nil, help:, type: nil, dev_only: false)
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
      o.dev_only = dev_only
      o.describe = short ? "#{short} [#{long}]" : long
      o.specified = false

      o.value = case type
      when :flag
        false
      when :value
        nil
      when :array
        []
      when :hash
        {}
      else
        JABA.error("Invalid type '#{type}'. Must be :flag, :value, :array or :hash.")
      end

      @options << o
      o
    end

    ##
    #
    def get_option(arg, fail_if_not_found: true)
      o = @options.find do |o|
        arg == o.long || arg == o.short
      end
      if !o && fail_if_not_found
        JABA.error("'#{arg}' option not defined")
      end
      o
    end

    ##
    #
    def option_defined?(arg)
      get_option(arg, fail_if_not_found: false) != nil
    end

    ##
    #
    def option_specified?(arg)
      get_option(arg).specified
    end

    ##
    #
    def option_value(arg)
      get_option(arg).value
    end

  end

  ##
  #
  class InputManager

    attr_reader :cmd
    attr_reader :passthru_args

    ##
    #
    def initialize(services, argv)
      @services = services
      @argv = argv
      @passthru_args = []
      @cmds = []
      @cmd = nil

      # General non-cmd-specific options
      #
      @null_cmd = register_cmd(:null, help: '') do |c|
        c.add_option('--help', help: 'Show help', type: :flag)
        c.add_option('--dry-run', help: 'Perform a dry run', type: :flag)
        c.add_option('--profile', help: 'Profiles with ruby-prof gem', type: :flag, dev_only: true)
        c.add_option('--barebones', help: 'Loads minimal modules', type: :flag, dev_only: true)
        c.add_option('--verbose', help: 'Prints extra information', type: :flag)
      end

      @cmd = register_cmd(:gen, help: 'Regenerate buildsystem') do |c|
        c.add_option('--src-root', short: '-S', help: 'Set src root', type: :value)
        c.add_option('--build-root', short: '-B', help: 'Set build root', type: :value)
        c.add_option('--define', short: '-D', help: 'Set global attribute value', type: :hash)
        c.add_option('--dump-state', help: 'Dump state to json for debugging', type: :flag)
      end
      
      register_cmd(:build, help: 'Execute build')
      register_cmd(:clean, help: 'Clean build')
      register_cmd(:help, help: 'Open jaba web help')
    end

    ##
    #
    def register_cmd(id, help:, dev_only: false, &block)
      JABA.error("cmd id must be a symbol") if !id.symbol?
      if id !~ /^[a-zA-Z0-9\-]+$/
        JABA.error("Invalid cmd id '#{id}' specified. Can only contain [a-zA-Z0-9-]")
      end
      c = Cmd.new(id, help, dev_only, &block)
      @cmds << c
      c
    end

    ##
    #
    def register_cmd_option(cmd_id, ...)
      get_cmd(cmd_id).add_option(...)
    end

    ##
    #
    def cmd_specified?(id)
      get_cmd(id, fail_if_not_found: true) # Validate cmd exists
      @cmd&.id == id
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
    def get_option(id)
      @null_cmd.get_option(id, fail_if_not_found: false) || @cmd&.get_option(id, fail_if_not_found: false)
    end

    ##
    #
    def option_defined?(id)
      get_option(id) != nil
    end

    ##
    #
    def cmd_option_specified?(cmd_id, option_id)
      get_cmd(cmd_id).option_specified?(option_id)
    end

    ##
    #
    def cmd_option_value(cmd_id, option_id)
      get_cmd(cmd_id).option_value(option_id)
    end

    ##
    #
    def usage_error(msg)
      JABA.error(msg, want_backtrace: false)
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
        w << "Current src_root: #{@services.src_root}"
        w << ""
      end
      w << "Usage:"
      w << ""
      w << "  jaba cmd [options]"
      w << ""
      w << "Commands:"
      w << ""
      
      @cmds.each do |c|
        next if c.dev_only || c == @null_cmd
        print_cmd_help(c, w)
        w << ""
      end

      w << "General options:"
      w << ""
      print_cmd_help(@null_cmd, w)

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

      if cmd != @null_cmd
        opts.concat(cmd.options.select{|o| !o.dev_only})
        cmd_str = "  #{cmd.id}"
        if cmd == @cmd
          cmd_str << ' (default)'
        end
        items << cmd_str
        help_items << cmd
      else
        opts.concat(cmd.options.select{|o| !o.dev_only && o.long != '--help'})
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

    ##
    #
    def process
      @argv = @argv.dup # Leave original argv untouched

      # Strip pasthru args from argv and store.
      #
      i = @argv.find_index{|a| a == '--'}
      if !i.nil?
        @passthru_args.concat(@argv.slice!(i, @argv.size - 1))
        @passthru_args.shift
      end

      @fsm = FSM.new
      @fsm.add_state(WantCmdState)
      @fsm.add_state(WantOptionState)
      @fsm.add_state(UnknownOptionState)
      @fsm.add_state(ValueState)
      @fsm.add_state(ArrayState)
      @fsm.add_state(GlobalAttrState)

      @fsm.argv = @argv
      @fsm.input_manager = self
      @fsm.input = @input
      @fsm.unknown_argv = []

      @fsm.on_run do
        while !argv.empty?
          arg = argv.shift
          send_event(:process_arg, arg)
        end
      end

      process_cmd_line
    end

    ##
    # This is called twice as plugins can register additional commands and options after the first pass.
    #
    def process_cmd_line
      return if @argv.empty?
      
      @fsm.run
      @argv.replace(@fsm.unknown_argv)
      @fsm.unknown_argv.clear
    end

    ##
    #
    def finalise
      if !@argv.empty?
        if @argv.size == 1
          usage_error("'#{@cmd.id}' command does not support #{@argv[0]} option")
        else
          usage_error("'#{@cmd.id}' command does not support #{@argv.join(', ')} options")
        end
      end
      if input.show_help
        show_help
      end
    end

    class WantCmdState
      def on_process_arg(arg)
        if arg.start_with?('-')
          fsm.argv.unshift(arg)
          goto WantOptionState
        else
          cmd = fsm.input_manager.get_cmd(arg.to_sym, fail_if_not_found: false)
          if cmd
            fsm.input_manager.instance_variable_set(:@cmd, cmd)
            goto WantOptionState
          else
            goto UnknownOptionState, arg
          end
        end
      end
    end

    class WantOptionState
      def on_process_arg(arg)
        opt = fsm.input_manager.get_option(arg)
        if opt
          case opt.long
          when '--define'
            goto GlobalAttrState, opt
          else
            case opt.type
            when :flag
              opt.value = true
            when :value
              goto ValueState, opt
            when :array
              goto ArrayState, opt
            end
          end
        else
          goto UnknownOptionState, arg
        end
      end
    end
    
    class UnknownOptionState
      def on_enter(arg)
        fsm.unknown_argv << arg
      end
      def on_process_arg(arg)
        if fsm.input_manager.option_defined?(arg)
          fsm.argv.unshift(arg)
          goto WantOptionState
        else
          fsm.unknown_argv << arg
        end
      end
    end
    
    class ValueState
      def on_enter(opt)
        @opt = opt
      end
      def on_exit
        if @opt.value.nil?
          fsm.input_manager.usage_error("#{@opt.describe} expects a value")
        end
      end
      def on_process_arg(arg)
        if fsm.input_manager.option_defined?(arg)
          fsm.argv.unshift(arg)
        else
          @opt.value = arg
        end
        goto WantOptionState
      end
    end

    class ArrayState
      def on_enter(opt)
        @opt = opt
      end
      def on_exit
        if @opt.value.empty?
          fsm.input_manager.usage_error("#{@opt.describe} expects 1 or more values")
        end
      end
      def on_process_arg(arg)
        if fsm.input_manager.option_defined?(arg)
          fsm.argv.unshift(arg)
          goto WantOptionState
        else
          @opt.value << arg
        end
      end
    end

    class GlobalAttrState
      def on_enter(opt)
        @opt = opt
        @values = []
      end
      def on_exit
        if @values.empty?
          fsm.input_manager.usage_error('No attribute name supplied')
        else
          @attr_name = @values.shift
        end
        if @values.empty?
          fsm.input_manager.usage_error("'#{@attr_name}' expects a value")
        end
        @opt.value[@attr_name] = @values
      end
      def on_process_arg(arg)
        if fsm.input_manager.option_defined?(arg)
          fsm.argv.unshift(arg)
          goto WantOptionState
        else
          case arg
          when /^(.+)=(.+)$/
            @values << Regexp.last_match(1)
            @values << Regexp.last_match(2)
          when /,/
            @values.concat(arg.split(','))
          else
            @values << arg
          end
        end
      end
    end
  end
end
