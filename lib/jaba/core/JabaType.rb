module JABA

##
#
class AttributeType

  attr_reader :default
  attr_reader :type
  attr_reader :validator
  
  ##
  #
  def initialize(services, type_id)
    @services = services
    @type = type_id
    @default = nil
    @validator = nil
  end

  ##
  #
  def set_var(var, val)
    instance_variable_set("@#{var}", val)
  end
  
  ##
  #
  def set_block(var, &block)
    if !block_given?
      raise 'Must provide a block'
    end
    instance_variable_set("@#{var}", block)
  end
  
end

##
# eg project/workspace/category etc.
#
class JabaType

  attr_reader :type
  
  ##
  #
  def initialize(services, type_id)
    @services = services
    @type = type_id
    @attribute_defs = []
  end
  
  ##
  #
  def define_attr(id, **options, &block)
    if !id.is_a?(Symbol)
      @services.definition_error("'#{id}' attribute id must be specified as a symbol", block.source_location)
    end
    if @attribute_defs.find{|d| d.id == id}
      @services.definition_error("'#{id}' attribute multiply defined", block.source_location)
    end
    ad = AttributeDefinition.new(@services, id, block.source_location)
    api = @services.attr_definition_api
    api.__internal_set_obj(ad)
    api.instance_eval(&block) if block_given?
    @attribute_defs << ad
  end
  
  ##
  #
  def extend_attr(id, **options, &block)
  end
  
  ##
  #
  def each_attr(&block)
    @attribute_defs.each(&block)
  end
  
  ##
  #
  def init
    @attribute_defs.each(&:init)
  end
  
end

##
# Manages shared data that is common to Attributes instanced from this definition.
#
class AttributeDefinition

  attr_reader :id
  attr_reader :type # eg :bool, :file, :path etc
  attr_reader :default
  
  ##
  #
  def initialize(services, id, source_location)
    @services = services
    @id = id
    @source_location = source_location

    @default = nil
    @flags = nil
    @help = nil
    @items = nil
    @options = nil
    @type = nil
    @type_obj = nil
  end
  
  ##
  #
  def set_var(var, val=nil, &block)
    if block_given?
      if !val.nil?
        raise 'Must provide a default value or a block but not both' # TODO: test
      end
      instance_variable_set("@#{var}", block)
    else
      instance_variable_set("@#{var}", val)
      case var
      when :type
        # Convert type id to AttributeType object
        #
        @type_obj = @services.get_attribute_type(@type)
        if !@type_obj
          @services.definition_error("'#{@type}' attribute type is undefined. Valid types: #{@services.jaba_attr_types.map{|at| at.type}}", caller[1])
        end
      end
    end
  end
  
  ##
  #
  def init
    if @type_obj
      # If default has not already been set fall back to the default specified by the attribute type, if one
      # has been set there.
      #
      if @default.nil?
        default_hook = @type_obj.default
        
        if default_hook
          @default = instance_eval(&default_hook)
        end
      end
      
      v = @type_obj.validator
      if v
        begin
          instance_eval(&v)
        rescue => e
          @services.definition_error("'#{id}' attribute definition failed validation: #{e.message.capitalize_first}", @source_location)
        end
      end
    end
  end
  
end

end
