module JABA

##
#
class JabaBase
  
  attr_reader :services
  
  ##
  #
  def initialize(services)
    @services = services
  end
  
end

##
#
class AttributeType < JabaBase

  attr_reader :type
  attr_reader :value_validator
  attr_reader :init_attr_hook
  
  ##
  #
  def initialize(services, type_id)
    super(services)
    @type = type_id
    @value_validator = nil
    @init_attr_hook = nil
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
      @services.jaba_error('Must provide a block')
    end
    instance_variable_set("@#{var}", block)
  end
  
end

##
# Manages shared data that is common to Attributes instanced from this definition.
#
class AttributeDefinition < JabaBase

  attr_reader :id
  attr_reader :type # eg :bool, :file, :path etc
  attr_reader :type_obj # AttributeType object
  attr_reader :default
  attr_reader :source_location
  
  ##
  #
  def initialize(services, id, type, jaba_type_obj, source_location)
    super(services)
    @id = id
    @type = type
    @jaba_type_obj = jaba_type_obj
    @source_location = source_location

    @child_attrs = []
    
    @default = nil
    @flags = []
    @help = nil
    @items = nil
    
    @type_obj = @services.get_attribute_type(@type)
    
    if @type_obj.init_attr_hook
      api = @services.attr_definition_api
      api.__internal_set_obj(self)
      api.instance_eval(&@type_obj.init_attr_hook)
    end
  end
  
  ##
  #
  def has_flag?(flag)
    (@flags and @flags.index(flag) != nil)
  end
  
  ##
  #
  def define_child_attr(id, child_type:, **options, &block)
    ad = @jaba_type_obj.define_attr(child_type, **options, &block)
    @child_attrs << ad
  end
  
  ##
  #
  def set_var(var_name, val=nil, **options, &block)
    if block_given?
      if !val.nil?
        @services.jaba_error('Must provide a default value or a block but not both')
      end
      instance_variable_set("@#{var_name}", block)
    else
      var = instance_variable_get("@#{var_name}")
      if var.is_a?(Array)
        var.concat(Array(val))
      else
        instance_variable_set("@#{var_name}", val)
      end
    end
  end
  
  ##
  #
  def init
    if @default
      vv = @type_obj.value_validator
      if vv
        begin
          instance_exec(@default, &vv)
        rescue => e
          @services.jaba_error("'#{id}' attribute definition failed validation: #{e.message.capitalize_first}", callstack: [e.backtrace[0], @source_location.join(':')]) # TODO: wrap up a bit nicer so join not required
        end
      end
    end
  end
  
end

##
# eg project/workspace/category etc.
#
class JabaType < JabaBase

  attr_reader :type
  attr_reader :generators
  
  ##
  #
  def initialize(services, type_id)
    super(services)
    @type = type_id
    @attribute_defs = []
    @generators = []
  end
  
  ##
  #
  def define_attr(id, type: nil, **options, &block)
    if !id.is_a?(Symbol)
      @services.jaba_error("'#{id}' attribute id must be specified as a symbol")
    end
    if !block_given?
      @services.jaba_error("'#{id}' attribute requires a block")
    end
    if @attribute_defs.find{|d| d.id == id}
      @services.jaba_error("'#{id}' attribute multiply defined")
    end
    ad = AttributeDefinition.new(@services, id, type, self, block.source_location)
    api = @services.attr_definition_api
    api.__internal_set_obj(ad)
    api.instance_eval(&block)
    @attribute_defs << ad
    ad
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
  def define_generator(&block)
    @generators << block
  end
  
  ##
  #
  def init
    @attribute_defs.each(&:init)
  end
  
end

end
