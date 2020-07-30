# frozen_string_literal: true

##
#
module JABA

  using JABACoreExt

  CmdLineOption = Struct.new(:long, :short, :help, :type, :var, :hidden)

  ##
  #
  class InputManager

    attr_reader :input

    ##
    #
    def initialize(services)
      @services = services
      @options = []

      @input = Input.new
      @input.instance_variable_set(:@argv, ARGV)
      @input.instance_variable_set(:@definitions, [])
      @input.instance_variable_set(:@src_root, nil)

      register_option(long: '--help', help: 'Show help')
      register_option(long: '--define', short: '-D', help: 'Set global attribute value')
      register_option(long: '--dry-run', help: 'Perform a dry run', type: :flag, var: :dry_run)
      register_option(long: '--barebones', help: 'Runs in barebones mode', type: :flag, var: :barebones, hidden: true)
      register_option(long: '--gen-ref', help: 'Generates reference doc', type: :flag, var: :generate_reference_doc, hidden: true)
    end

    ##
    #
    def register_option(long:, short: nil, help:, type: nil, var: nil, hidden: false)
      if long !~ /^--[a-zA-Z0-9\-]/
        @services.jaba_error("Invalid long option format '#{long}' specified. Must be of form --my-long-option")
      end
      if short && short !~ /^-[a-zA-Z]$/
        @services.jaba_error("Invalid short option format '#{short}' specified. Must be of form -O")
      end
      @options << CmdLineOption.new(long, short, help, type, var, hidden)
      if var
        @input.define_singleton_method(var) do
          instance_variable_get("@#{var}")
        end
        case type
        when :flag
          @input.instance_variable_set("@#{var}", false)
        end
      end
    end

    ##
    #
    def process
      process_cmd_line(phase: 2)

      # TODO: automatically patch in new attrs
      if !JABA.running_tests?
        config_file = "#{@services.globals.build_root}/config.jaba"
        if !File.exist?(config_file)
          make_jaba_config(config_file)
        end
      end
    end

    ##
    # TODO: don't use jaba_error
    def process_cmd_line(phase: 1)
      services = @services
      options = @options
      input = @input
      input_manager = self

      # Take a copy because cmd line is parsed twice
      #
      argv = services.input.argv.dup

      if !argv.array?
        jaba_error("'argv' must be an array")
      end
      
      FSM.new(events: [:process_arg]) do
        state :default do
          on_process_arg do |arg|
            opt = options.find do |o|
              arg.start_with?(o.long) || (o.short && arg.start_with?(o.short))
            end

            if opt.nil?
              services.jaba_error("'#{arg}' option not recognised")
            end

            # See if value was tacked on the end. If so, split and start again
            #
            if arg =~ /^(#{opt.long})(.+)$/ || (opt.short && arg =~ /^(#{opt.short})(.+)$/)
              argv.unshift(Regexp.last_match(2))
              argv.unshift(Regexp.last_match(1))
              next
            end

            case opt.long
            when '--help'
              if phase == 2
                input_manager.show_help
              end
            when '--define'
              if phase == 1
                goto :ignore # Ignore global attribute definition in phase 1 as globals not set up yet
              else
                goto :attribute
              end
            else
              if phase == 2
                goto :ignore
              elsif opt.type == :flag
                input.instance_variable_set("@#{opt.var}", true)
              end
            end
          end
        end
        state :ignore do
          on_process_arg do |arg|
            if arg.start_with?('-')
              argv.unshift(arg)
              goto :default
            end
          end
        end
        state :attribute do
          on_enter do
            @attr = nil
          end
          on_exit do
            if @attr.nil?
              services.jaba_error('No attribute name supplied')
            end
          end
          on_process_arg do |arg|
            @attr = services.globals_node.get_attr(arg.to_sym, fail_if_not_found: false)
            if !@attr
              services.jaba_error("'#{arg}' attribute not defined in :globals type")
            end
            case @attr.attr_def.variant
            when :single
              goto :single, @attr
            when :array
              goto :array, @attr
            when :hash
              goto :hash, @attr
            end
          end
        end
        state :single do
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
              services.jaba_error("No value provided for '#{arg}'")
            end
            if @attr.type_id == :file || @attr.type_id == :dir
              @value = @value.to_absolute(clean: true)
            end
            @attr.set(@value)
          end
          on_process_arg do |arg|
            if arg.start_with?('-')
              argv.unshift(arg)
            else
              @value = @type.from_string(arg)
            end
            goto :default
          end
        end
        state :array do
          on_enter do |attr|
            @attr = attr
            @type = attr.attr_def.jaba_attr_type
            @elems = []
          end
          on_exit do
            @attr.set(@elems)
          end
          on_process_arg do |arg|
            if arg.start_with?('-')
              if @elems.empty?
                services.jaba_error("No valued provided for '#{arg}'")
              else
                argv.unshift(arg)
                goto :default
              end
            end
            val = @type.from_string(arg)
            @elems << val
          end
        end
        state :hash do
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
            if arg.start_with?('-')
              if @elems.empty?
                services.jaba_error("No valued provided for '#{arg}'")
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
      w << "Welcome to Jaba"

      puts w
      exit
    end

  end

end
