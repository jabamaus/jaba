module JABA
  class AttributeBase
    def initialize(attr_def, node)
      @attr_def = attr_def
      @node = node
      @last_call_location = nil
      @set = false
    end

    def to_s = "#{type_id} attribute" # For debugger
    def describe = "'#{@attr_def.name}' attribute"
    def node = @node
    def type_id = @attr_def.type_id
    def name = @attr_def.name
    def attr_def = @attr_def
    def set? = @set
    def required? = @attr_def.has_flag?(:required)
    def read_only? = attr_def.has_flag?(:read_only)
    def src_loc = @last_call_location
    def last_call_location = @last_call_location
    def set_last_call_location(loc) = @last_call_location = loc
    def attr_error(msg, errobj: self) = JABA.error(msg, errobj: errobj)
    def attr_warn(msg, warnobj: self) = JABA.warn(msg, line: warnobj.src_loc)
    def process_flags; end # override as necessary

    # TODO: attribute_array does not have @value...
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
      compound = Node.new
      compound.init(attr_def.compound_def, nil, @last_call_location, @node)
      compound.add_attrs(attr_def.compound_def.attr_defs)
      compound.eval_jdl(&block) if block
      compound.post_create
      @set = true
      compound
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
      @flag_options = []
      @value_options = KeyToSHash.new
      @in_on_set = false
    end

    def value
      if attr_def.compound? && JABA.context.executing_jdl?
        @value.api_obj
      else
        @value.freeze
      end
    end

    def flag_options = @flag_options
    def value_options = @value_options

    # This can only be called after the value has had its final value set as it gives raw access to value.
    def raw_value = @value

    def set(*args, __force: false, __map: true, **kwargs, &block)
      attr_error("#{describe} is read only") if read_only? && !__force

      new_value = if block_given?
          value_from_block(&block)
        else
          args.shift
        end

      args.each do |f|
        if !attr_def.has_flag_option?(f)
          attr_error("Invalid flag option '#{f.inspect_unquoted}' passed to #{describe}. Valid flags are #{attr_def.flag_options}")
        end
        if @flag_options.include?(f)
          attr_warn("#{describe} was passed duplicate flag '#{f.inspect_unquoted}'")
        else
          @flag_options << f
        end
      end

      kwargs.each do |k, v|
        option_def = @attr_def.lookup_option_def(k, self)
        a = @value_options[k]
        if a.nil?
          a = case option_def.variant
            when :single
              AttributeSingle.new(option_def, @node)
            when :array
              AttributeArray.new(option_def, @node)
            when :hash
              AttributeHash.new(option_def, @node)
            end
          @value_options[k] = a
        end
        a.set_last_call_location(last_call_location)
        a.set(v)
      end

      attr_type = @attr_def.attr_type

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

      @value = __map ? attr_type.map_value(new_value, self) : new_value
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

    def option_value(name)
      @attr_def.lookup_option_def(name, self) # check its valid
      attr = @value_options ? @value_options[name] : nil
      return nil if attr.nil?
      attr.value
    end

    def <=>(other)
      result = if @value.respond_to?(:casecmp)
        raw_value.casecmp(other.raw_value)
      else
        raw_value <=> other.raw_value
      end
      if result.nil?
        attr_error("Failed to compare #{describe}::#{raw_value} with #{other.describe}::#{other.raw_value}")
      end
      result
    end

    # This can only be called after the value has had its final value set as it gives raw access to value.
    def map_value! = @value = yield(@value)
    def visit_elem = yield self
  end

  class AttributeSingle < AttributeElement
    def value
      if !set?
        if attr_def.compound?
          @value = make_compound_attr
          if JABA.context.executing_jdl?
            @value.api_obj
          else
            @value
          end
        elsif attr_def.default_set?
          val = JABA.context.execute_attr_def_block(self, attr_def.default)
          # TODO: need to do validation here
          @attr_def.attr_type.map_value(val, self).freeze
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
        #  if attr_def.default_set?
        #    set(JABA.context.execute_attr_def_block(self, attr_def.default))
        #  end
      end
    end
  end
end
