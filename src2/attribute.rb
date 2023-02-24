module JABA
  class AttributeBase
    def initialize(attr_def, node)
      @attr_def = attr_def
      @node = node
      @last_call_location = nil
      @set = false
    end

    def node = @node
    def type_id = @attr_def.type_id
    def attr_def = @attr_def
    def set? = @set
    def required? = @attr_def.has_flag?(:required)
    def read_only? = attr_def.has_flag?(:read_only)
    def src_loc = @last_call_location

    def attr_error(msg) = JABA.error(msg, errobj: self)

    def call_validators
      begin
        yield
      rescue => e
        attr_error("#{describe} invalid: #{e.message}")
      end
    end

    def value_from_block(&block) = @node.eval_jdl(&block)
  end

  class AttributeElement < AttributeBase
    def initialize(attr_def, node)
      super
      @value = nil
      @flag_options = nil
      @value_options = nil
    end

    def value = @value

    def set(*args, validate: true, **kwargs, &block)
      @last_call_location = if JABA.context.executing_jdl?
          $last_call_location
        else
          calling_location
        end
      if read_only? && set? # allow read only to be set the first time so they an be initialised
        attr_error("#{describe} is read only")
      end
      new_value = if block_given?
          value_from_block(&block)
        else
          args.shift
        end
      attr_type = @attr_def.attr_type
      @flag_options = args
      # Take a deep copy of value_options so they are private to this attribute
      @value_options = kwargs.empty? ? {} : Marshal.load(Marshal.dump(kwargs))

      if validate
        @flag_options.each do |f|
          if !attr_def.has_flag_option?(f)
            attr_error("Invalid flag option '#{f.inspect_unquoted}' passed to #{describe}. Valid flags are #{attr_def.get_flag_options}")
          end
        end
        if !new_value.nil?
          call_validators do
            attr_type.validate_value(@attr_def, new_value)
            attr_def.validate_value(new_value)
            #@attr_def.call_block_property(:validate, new_value, @flag_options, **@value_options)
          end
        end
      end
      @value = new_value
      @value.freeze # Prevents value from being changed directly after it has been returned by 'value' method
      @set = true
    end

    def has_flag_option?(o) = @flag_options&.include?(o)

    def get_option_value(key, fail_if_not_found: true)
      attr_def.get_value_option(key)
      if !@value_options.key?(key)
        if fail_if_not_found
          attr_error("Option key '#{key}' not found in #{describe}")
        else
          return nil
        end
      end
      @value_options[key]
    end
  end

  class AttributeSingle < AttributeElement
    def initialize(attr_def, node)
      super
      if !attr_def.default_is_block? && !attr_def.get_default.nil?
        set(attr_def.get_default)
      end
    end

    def describe = "'#{@node.id}.#{@attr_def.name}' attribute"

    def value
      @last_call_location = if JABA.context.executing_jdl?
          $last_call_location
        else
          calling_location
        end
      if !set?
        if attr_def.default_is_block?
          val = JABA.context.execute_attr_default_block(self)
        elsif JABA.context.in_attr_default_block?
          outer = JABA.context.outer_default_attr_read
          outer.attr_error("#{outer.describe} default read uninitialised #{describe} - #{describe} might need a default value")
        else
          nil
        end
      else
        @value
      end
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
