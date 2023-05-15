module JABA
  class AttributeBase
    def initialize(attr_def, node)
      @attr_def = attr_def
      @node = node
      @last_call_location = nil
      @set = false
    end

    def to_s = "#{type_id} attribute"
    def node = @node
    def type_id = @attr_def.type_id
    def name = @attr_def.name
    def attr_def = @attr_def
    def set? = @set
    def required? = @attr_def.has_flag?(:required)
    def read_only? = attr_def.has_flag?(:read_only)
    def src_loc = @last_call_location
    def attr_error(msg, errobj: self) = JABA.error(msg, errobj: errobj)
    def process_flags; end # override as necessary

    def value_from_block(&block)
      if attr_def.compound?
        if @value # If compound has already been made but is being set again, re-evaluate existing value against block
          @value.eval_jdl(&block)
          return @value
        else
          return make_compound_attr(&block)
        end
      else
        @node.eval_jdl(&block)
      end
    end

    protected

    def make_compound_attr(&block)
      compound = Node.new(attr_def.compound_def, nil, @last_call_location, @node)
      compound.add_attrs(attr_def.compound_def.attr_defs)
      compound.eval_jdl(&block) if block
      compound.post_create
      @set = true
      compound
    end

    def record_last_call_location
      @last_call_location = if JABA.context.executing_jdl?
          $last_call_location
        else
          calling_location(1)
        end
    end

    def rescue_on_validate
      begin
        yield
      rescue => e
        attr_error("#{describe} invalid - #{e.raw_message}")
      end
    end
  end

  class AttributeElement < AttributeBase
    def initialize(attr_def, node)
      super
      @value = nil
      @flag_options = nil
      @value_options = nil
      @in_on_set = false
    end

    def describe = "'#{@attr_def.name}' attribute element"

    def value
      record_last_call_location
      if attr_def.compound? && JABA.context.executing_jdl?
        @value.api_obj
      else
        @value.freeze
      end
    end

    def flag_options = @flag_options

    # This can only be called after the value has had its final value set as it gives raw access to value.
    def raw_value = @value

    def set(*args,
            __validate: true,
            __force: false,
            **kwargs, &block)
      record_last_call_location
      attr_error("#{describe} is read only") if read_only? && !__force

      new_value = if block_given?
          value_from_block(&block)
        else
          args.shift
        end

      @flag_options = args
      # Take a deep copy of value_options so they are private to this attribute
      @value_options = {}
      kwargs.each do |k, v|
        @value_options[k] = v.dup
      end

      attr_type = @attr_def.attr_type

      if __validate
        @flag_options.each do |f|
          if !attr_def.has_flag_option?(f)
            attr_error("Invalid flag option '#{f.inspect_unquoted}' passed to #{describe}. Valid flags are #{attr_def.flag_options}")
          end
        end
        if !new_value.nil?
          # Validate whether it is a single value/array before validating type
          attr_def.validate_value(new_value) do |msg|
            attr_error("#{describe} invalid - #{msg}")
          end
          attr_type.validate_value(@attr_def, new_value) do |msg|
            attr_error("#{describe} invalid - #{msg}")
          end
          if attr_def.on_validate
            rescue_on_validate do
              node.eval_jdl(new_value, @flag_options, **@value_options, &attr_def.on_validate)
            end
          end
        end
      end
      @value = attr_type.map_value(new_value, self)
      @set = true

      if attr_def.on_set
        if @in_on_set
          attr_error("Reentrancy detected in #{describe} on_set")
        end
        @in_on_set = true
        @node.eval_jdl(new_value, &attr_def.on_set)
        @in_on_set = false
      end
    end

    def has_flag_option?(o) = @flag_options&.include?(o)

    def option_value(key, fail_if_not_found: true)
      attr_def.value_option(key)
      if !@value_options.key?(key)
        if fail_if_not_found
          attr_error("Option key '#{key}' not found in #{describe}")
        else
          return nil
        end
      end
      @value_options[key]
    end

    def <=>(other)
      if @value.respond_to?(:casecmp)
        @value.to_s.casecmp(other.value.to_s) # to_s is required because symbols need to be compared to strings
      else
        @value <=> other.value
      end
    end
  end

  class AttributeSingle < AttributeElement
    def describe = "'#{@attr_def.name}' attribute"

    def value
      record_last_call_location
      if !set?
        if attr_def.compound?
          @value = make_compound_attr
          if JABA.context.executing_jdl?
            @value.api_obj
          else
            @value
          end
        elsif attr_def.default_is_block?
          val = JABA.context.execute_attr_def_block(self, attr_def.default)
          @attr_def.attr_type.map_value(val, self).freeze
        elsif attr_def.default_set?
          @attr_def.attr_type.map_value(attr_def.default, self).freeze
        elsif JABA.context.in_attr_def_block?
          outer = JABA.context.outer_attr_def_block_attr
          outer.attr_error("#{outer.describe} default read uninitialised #{describe} - it might need a default value")
        else
          nil
        end
      elsif attr_def.compound? && JABA.context.executing_jdl?
        @value.api_obj
      else
        @value.freeze
      end
    end

    # If the attribute was never set by the user and it has a default set ensure that the default value
    # is applied. Call set with no args to achieve this.
    #
    def finalise
      # TODO: exercise this code in test
      if !set?
      #  if attr_def.default_is_block?
      #    set(JABA.context.execute_attr_def_block(self, attr_def.default))
      #  elsif attr_def.default_set?
      #    set(attr_def.default)
      #  end
      end
    end
  end
end
