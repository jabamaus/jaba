# frozen_string_literal: true

##
#
module JABA

  using JABACoreExt

  ##
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
      services = @services
      input_node = services.input_singleton
      argv = services.input.argv
      if !argv.array?
        jaba_error("'argv' must be an array")
      end
      
      # TODO: don't like how globals are handled
      FSM.new(events: [:process_arg]) do
        state :default do
          on_process_arg do |arg|
            if arg !~ /--(.*)/
              services.jaba_error("Invalid option format '#{arg}'")
            end
            name = Regexp.last_match(1).to_sym
            attr = input_node.get_attr(name, fail_if_not_found: false)
            variant = attr.attr_def.variant
            type_id = attr.attr_def.type_id
            case variant
            when :single
              if type_id == :bool
                attr.set(true)
              else
                goto :single, attr
              end
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
          end
          on_process_arg do |arg|
            if arg.start_with?('-')
              services.jaba_error("No value provided for '#{arg}'")
            else
              val = @type.from_string(arg)
              @attr.set(val)
              goto :default
            end
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

  end

end
