module JABA
  class AttributeBase
    def initialize(attr_def, node)
      @attr_def = attr_def
      @node = node
      @last_call_location = nil
      @set = false
    end

    def type_id = @attr_def.type_id
    def attr_def = @attr_def
    def set? = @set
    def required? = @attr_def.has_flag?(:required)
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

    def value_from_block(&block)
      @node.eval_jdl(&block)
    end
  end

  class AttributeElement < AttributeBase
    def initialize(attr_def, node)
      super
      @value = nil
    end

    def value = @value

    def set(*args, validate: true, &block)
      @last_call_location = if JABA.context.executing_jdl?
          $last_call_location
        else
          calling_location
        end
      new_value = if block_given?
          value_from_block(&block)
        else
          args.shift
        end
      attr_type = @attr_def.attr_type
      if validate
        if !new_value.nil?
          call_validators do
            attr_type.validate_value(@attr_def, new_value)
            attr_def.validate_value(new_value)
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
      if !attr_def.default_is_block? && !attr_def.get_default.nil?
        set(attr_def.get_default)
      end
    end

    def describe
      "'#{@node.id}.#{@attr_def.name}' attribute"
    end

    # If attribute's default value was specified as a block it is executed here, after the node has been created, since
    # default blocks can be implemented in terms of other attributes. If the user has already supplied a value then the
    # default block will not be executed.
    #
    def finalise
      #return if !@default_block || @set
      #val = Context.instance.execute_attr_default_block(@node, @default_block)
      #set(val)
    end
  end
end
