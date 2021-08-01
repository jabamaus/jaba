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
      register_option('--help', help: 'Show help', type: :flag, var: :show_help)
      register_option('--dry-run', help: 'Perform a dry run', type: :flag, var: :dry_run)
      register_option('--profile', help: 'Profiles with ruby-prof gem', type: :flag, var: :profile, dev_only: true)
      register_option('--barebones', help: 'Loads minimal modules', type: :flag, var: :barebones, dev_only: true)

      @default_cmd = register_cmd(:gen, help: 'Regenerate buildsystem')
      register_option('--src-root', short: '-S', help: 'Set src root', type: :value, var: :src_root, cmd: :gen)
      register_option('--build-root', short: '-B', help: 'Set build root', type: :value, var: :build_root, cmd: :gen)
      register_option('--define', short: '-D', help: 'Set global attribute value', cmd: :gen)
      register_option('--dump-state', help: 'Dump state to json for debugging', type: :flag, var: :dump_state, cmd: :gen)
      
      register_cmd(:build, help: 'Execute build')
      register_cmd(:clean, help: 'Clean build')
      register_cmd(:help, help: 'Open jaba web help')
    end

    ##
    #
    def register_cmd(id, help:, dev_only: false)
      JABA.error("cmd id must be a symbol") if !id.symbol?
      if id !~ /^[a-zA-Z0-9\-]+$/
        JABA.error("Invalid cmd id '#{id}' specified. Can only contain [a-zA-Z0-9-]")
      end
      c = OpenStruct.new
      c.id = id
      c.help = help
      c.options = []
      c.dev_only = dev_only
      @cmds << c
      c
    end

    ##
    #
    def register_option(long, short: nil, help:, type: nil, var: nil, dev_only: false, cmd: nil)
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
      o.dev_only = dev_only
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
          JABA.error("Invalid type '#{type}'. Must be :flag, :value or :array.")
        end
        @input.instance_variable_set(o.inst_var, val)
      end
      o
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
    def process_cmd_line
      unknown = []
      
      FSM.new do |fsm|
        fsm.add_state(WantCmdState)
        fsm.add_state(WantOptionState)
        fsm.add_state(IgnoreState)
        fsm.add_state(ValueState)
        fsm.add_state(ArrayState)
        fsm.add_state(GlobalAttrState)

        fsm.set_var(:argv, input.argv)
        fsm.set_var(:input_manager, self)
        fsm.set_var(:input, @input)
        fsm.set_var(:default_cmd, @default_cmd)
        fsm.set_var(:unknown, unknown)

        fsm.on_run do
          while !@argv.empty?
            arg = @argv.shift
            break if arg == '--'
            send_event(:process_arg, arg)
          end
        end
      end
      input.argv = unknown
    end

    ##
    #
    def finalise
      if !input.argv.empty?
        usage_error("#{input.argv[0]} option not recognised")
      end
      if input.show_help
        show_help
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
        next if c.dev_only
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
        opts.concat(cmd.options.select{|o| !o.dev_only})
        cmd_str = "  #{cmd.id}"
        if cmd == @default_cmd
          cmd_str << ' (default)'
        end
        items << cmd_str
        help_items << cmd
      else
        opts.concat(@options.select{|o| !o.cmd && !o.dev_only && o.long != '--help'})
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

  class WantCmdState
    def on_process_arg(arg)
      cmd = nil
      if arg.start_with?('-')
        cmd = fsm.default_cmd
        fsm.argv.unshift(arg)
      else
        cmd = fsm.input_manager.get_cmd(arg.to_sym, fail_if_not_found: false)
        if cmd.nil?
          goto IgnoreState, arg
          return
        end
      end
      fsm.input.instance_variable_set(:@cmd, cmd.id)
      goto WantOptionState
    end
  end

  class WantOptionState
    def on_process_arg(arg)
      opt = fsm.input_manager.get_option(arg)

      if opt.nil?
        goto IgnoreState, arg
        return
      end

      case opt.long
      when '--define'
        goto GlobalAttrState
      else
        case opt.type
        when :flag
          fsm.input.instance_variable_set(opt.inst_var, true)
        when :value
          goto ValueState, opt
        when :array
          goto ArrayState, opt
        end
      end
    end
  end
  
  class IgnoreState
    def on_enter(arg)
      fsm.unknown << arg
    end
    def on_process_arg(arg)
      if fsm.input_manager.option_defined?(arg)
        fsm.argv.unshift(arg)
        goto WantOptionState
      else
        fsm.unknown << arg
      end
    end
  end
  
  class ValueState
    def on_enter(opt)
      @opt = opt
      @val = nil
    end
    def on_exit
      if @val.nil?
        fsm.input_manager.usage_error("#{@opt.describe} expects a value")
      end
      fsm.input.instance_variable_set(@opt.inst_var, @val)
    end
    def on_process_arg(arg)
      if fsm.input_manager.option_defined?(arg)
        fsm.argv.unshift(arg)
      else
        @val = arg
      end
      goto WantOptionState
    end
  end

  class ArrayState
    def on_enter(opt)
      @opt = opt
      @elems = []
    end
    def on_exit
      if @elems.empty?
        fsm.input_manager.usage_error("#{@opt.describe} expects 1 or more values")
      end
      ary = fsm.input.instance_variable_get(@opt.inst_var)
      ary.concat(@elems)
    end
    def on_process_arg(arg)
      if fsm.input_manager.option_defined?(arg)
        fsm.argv.unshift(arg)
        goto WantOptionState
      else
        @elems << arg
      end
    end
  end

  class GlobalAttrState
    def on_enter
      @attr_name = nil
      @values = []
    end
    def on_exit
      if @attr_name.nil?
        fsm.input_manager.usage_error('No attribute name supplied')
      end
      if @values.empty?
        fsm.input_manager.usage_error("'#{@attr_name}' expects a value")
      end
      fsm.input.global_attrs.push_value(@attr_name, @values)
    end
    def on_process_arg(arg)
      if fsm.input_manager.option_defined?(arg)
        fsm.argv.unshift(arg)
        goto WantOptionState
        return
      end

      if @attr_name.nil?
        @attr_name = arg
      else
        @values << arg
      end
    end
  end

end
