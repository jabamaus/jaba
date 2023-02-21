module JABA
  class AttributeBase
    def initialize(attr_def, node)
      @attr_def = attr_def
      @node = node
      @last_call_location = nil
      @set = false
    end

    def attr_def = @attr_def
    def set? = @set
    def src_loc = @last_call_location

    def attr_error(msg)
      JABA.error(msg, backtrace: @last_call_location)
    end

    def call_validators
      begin
        yield
      rescue => e
        attr_error("#{describe} invalid: #{e.message}")
      end
    end
  end

  class AttributeElement < AttributeBase
    def initialize(attr_def, node)
      super
      @value = nil
    end

    def value = @value

    def set(*args, validate: true)
      @last_call_location = if JABA.context.executing_jdl?
          $last_call_location
        else
          calling_location
        end
      new_value = args.shift
      attr_type = @attr_def.attr_type
      if validate
        if !new_value.nil?
          call_validators do
            attr_type.validate_value(@attr_def, new_value)
            #@attr_def.call_block_property(:validate, new_value, @flag_options, **@value_options)
          end
        end
      end
      @value = new_value
      @set = true
    end
  end

  class AttributeSingle < AttributeElement
    def initialize(attr_def, node)
      super
      if !attr_def.get_default.nil? && !attr_def.get_default.proc?
        set(attr_def.get_default)
      end
    end

    def describe
      "'#{@node.id}.#{@attr_def.name}' attribute"
    end
  end
end
