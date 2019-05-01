module JABA

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
  def register_attr(id, **options, &block)
    if !id.is_a?(Symbol)
      @services.definition_error("'#{id}' attribute id must be specified as a symbol")
    end
    if @attribute_defs.find{|d| d.id == id}
      @services.definition_error("'#{id}' attribute multiply defined")
    end
    ad = AttributeDefinition.new(id)
    api = @services.attr_definition_api
    api.__internal_set_obj(ad)
    api.instance_eval(&block) if block_given?
    @attribute_defs << ad
  end
  
  ##
  #
  def override_attr(id, **options, &block)
  end
  
  ##
  #
  def each_attr(&block)
    @attribute_defs.each(&block)
  end
  
end

##
# Manages shared data that is common to Attributes instanced from this definition.
#
class AttributeDefinition

  attr_reader :id
  
  ##
  #
  def initialize(id)
    @id = id

    @default = nil
    @flags = nil
    @help = nil
    @items = nil
    @options = nil
    @type = nil
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
  
end

end
