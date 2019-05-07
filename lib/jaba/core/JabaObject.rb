module JABA

##
#
class Attribute

  ##
  #
  def initialize(services, attr_def)
    @services = services
    @attr_def = attr_def
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
    if from_definitions
      vv = @attr_def.type_obj&.value_validator
      if vv
        begin
          instance_exec(value, &vv)
        rescue => e
          @services.definition_error("'#{@attr_def.id}' attribute failed validation: #{e.message.capitalize_first}", e.backtrace[0], backtrace: [caller[3]])
        end
      end
    end
    @value = value
  end
  
end

##
#
class JabaObject

  attr_reader :id
  
  ##
  #
  def initialize(services, jaba_type, id, source_location)
    @services = services
    @jaba_type = jaba_type
    @id = id
    @source_location = source_location
    
    @attributes = []
    @attribute_lookup = {}
    
    @generators = []

    @jaba_type.each_attr do |attr_def|
      a = Attribute.new(services, attr_def)
      if attr_def.type == :bool
        @attribute_lookup["#{attr_def.id}?".to_sym] = a
      end
      @attribute_lookup[attr_def.id] = a
      @attributes << a
    end
  end
  
  ##
  #
  def get_attr(id)
    @attribute_lookup[id]
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
    a = get_attr(id)

    if !a
      if called_from_definitions
        raw_id = id.to_s.chomp('?').to_sym # Remove any trailing '?' (used with boolean attrs) to get the raw name
        a2 = get_attr(raw_id)
        if a2
          @services.definition_error("'#{raw_id}' attribute is not of type :bool", caller[1])
        else
          @services.definition_error("'#{raw_id}' attribute not defined", caller[1])
        end
      else
        raise NoMethodError, "'#{id}' attribute not defined"
      end
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
