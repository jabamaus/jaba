module JABA

##
#
class Attribute

  ##
  #
  def initialize(attr_def)
    @def = attr_def
    set(attr_def.default)
  end
  
  ##
  #
  def get(from_definitions=false)
    @value
  end
  
  ##
  #
  def set(value, from_definitions=false, *options, prefix: nil, suffix: nil, **key_value_options, &block)
    @value = value
  end
  
end

##
#
class JabaObject

  ##
  #
  def initialize(jaba_type, def_data)
    @jaba_type = jaba_type
    @def_data = def_data
    
    @attributes = []
    @attribute_lookup = {}
    
    @generators = []

    @jaba_type.each_attr do |attr_def|
      a = Attribute.new(attr_def)
      if attr_def.type == :bool
        @attribute_lookup["#{attr_def.id}?".to_sym] = a
      end
      @attribute_lookup[attr_def.id] = a
      @attributes << a
    end
  end
  
  ##
  #
  def get_attr(id, fail_if_not_found: true)
    a = @attribute_lookup[id]
    raise NoMethodError, "'#{id}' attribute not found in '#{definition_id}'" if (!a and fail_if_not_found)
    a
  end
  
  ##
  #
  def define_generator(&block)
    @generators << block
  end
  
  ##
  #
  def call_generators
    @generators.each do |block|
      block.call
    end
  end
  
  ##
  #
  def include_shared(ids, args: [])
  end
  
  ##
  #
  def handle_attr(id, called_from_definitions, *args, **key_value_args, &block)
    getter = (args.empty? and key_value_args.empty?)
    a = get_attr(id, fail_if_not_found: false)

    # TODO: try to unify errors
    if called_from_definitions
      if !a
        definition_error("'#{id}' attribute not defined")
      end
    elsif !a
      raise NoMethodError, "'#{id}' attribute not defined"
    end
    
    if getter
      a.get(called_from_definitions)
    else
      a.set(args.shift, called_from_definitions, *args, **key_value_args, &block)
    end    
  end
  
  ##
  #
  def method_missing(attr_name, *args, **key_value_args, &block)
    handle_attr(attr_name, true, *args, **key_value_args, &block)
  end
  
end

end
