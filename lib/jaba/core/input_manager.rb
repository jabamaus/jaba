# frozen_string_literal: true

##
#
module JABA

  using JABACoreExt

  ##
  # TODO: support for short options
  # TODO: rename to JabaConfigurationManager or similar?
  #
  class InputManager

    ##
    #
    def initialize(services)
      @services = services
    end

    ##
    #
    def process
      process_cmd_line

      # TODO: automatically patch in new attrs
      if !JABA.running_tests?
        config_file = "#{@services.globals.build_root}/config.jaba"
        if !File.exist?(config_file)
          make_jaba_config(config_file)
        end
      end
    end

    ##
    #
    def process_cmd_line
      services = @services
      argv = services.input.argv

      if !argv.array?
        jaba_error("'argv' must be an array")
      end
      
      FSM.new(events: [:process_arg]) do
        state :default do
          on_process_arg do |arg|
            if arg !~ /--(.*)/
              services.jaba_error("Invalid option format '#{arg}'")
            end
            name = Regexp.last_match(1).gsub('-', '_').to_sym
            attr = services.globals_node.get_attr(name, fail_if_not_found: false)
            if !attr
              services.jaba_error("'#{arg}' option not recognised")
            end
            case attr.attr_def.variant
            when :single
              goto :single, attr
            when :array
              goto :array, attr
            when :hash
              raise 'not yet supported'
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

  end

end
