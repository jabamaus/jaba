module JABA

##
#
class AttributeType

  attr_reader :validator
  
  ##
  #
  def initialize(services, def_data)
    @services = services
    @def_data = def_data
    @validator = nil
  end
  
  ##
  #
  def type
    @def_data.type
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
      @services.definition_error('Must provide a block')
    end
    instance_variable_set("@#{var}", block)
  end
  
end

##
# eg project/workspace/category etc.
#
class JabaType

  ##
  #
  def initialize(services, def_data)
    @services = services
    @def_data = def_data
    @attribute_defs = []
  end
  
  ##
  #
  def type
    @def_data.type
  end
  
  ##
  #
  def define_attr(id, **options, &block)
    if !id.is_a?(Symbol)
      @services.definition_error("'#{id}' attribute id must be specified as a symbol")
    end
    if @attribute_defs.find{|d| d.id == id}
      @services.definition_error("'#{id}' attribute multiply defined")
    end
    ad = AttributeDefinition.new(@services, id)
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
  
  ##
  #
  def initialize(services, id)
    @services = services
    @id = id

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
        @services.definition_error('Must provide a default value or a block but not both')
      end
      instance_variable_set("@#{var}", block)
    else
      instance_variable_set("@#{var}", val)
    end
  end
  
  ##
  #
  def init
    # Convert type id to AttributeType object if type has been set
    #
    if @type
      @type_obj = @services.get_attribute_type(@type)
    end
    
    if @type_obj
      v = @type_obj.validator
      if v
        v.call
      end
    end
  end
  
end

end
