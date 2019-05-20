module JABA

##
#
class JabaAPIObject
  
  attr_reader :services
  attr_reader :api
  
  ##
  #
  def initialize(services, api)
    @services = services
    @api = api
  end
  
  ##
  #
  def api_eval(args=nil, &block)
    begin
      @api.__internal_set_obj(self)
      if !args.nil?
        @api.instance_exec(args, &block)
      else
        @api.instance_eval(&block)
      end
    rescue JabaError
      raise
    rescue Exception => e
      @services.jaba_error(e.message, callstack: e.backtrace)
    end
  end
  
  ##
  #
  def include_shared(ids, args)
    ids.each do |id|
      df = @services.get_definition(:shared, id, fail_if_not_found: false)
      if !df
        @services.jaba_error("Shared definition '#{id}' not found")
      end
      
      n_expected_args = df.block.arity
      n_supplied_args = args ? Array(args).size : 0
      
      if (n_supplied_args != n_expected_args)
        @services.jaba_error("shared definition '#{id}' expects #{n_expected_args} arguments but #{n_supplied_args} were passed")
      end
      
      api_eval(args, &df.block)
    end
  end
  
end

##
#
class AttributeType < JabaAPIObject

  attr_reader :type
  attr_reader :value_validator
  attr_reader :init_attr_hook
  attr_reader :attr_def_validator
  
  ##
  #
  def initialize(services, type_id)
    super(services, services.attr_type_api)
    @type = type_id
    @value_validator = nil
    @init_attr_hook = nil
    @attr_def_validator = nil
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
class AttributeDefinition < JabaAPIObject

  attr_reader :id
  attr_reader :type # eg :bool, :file, :path etc
  attr_reader :type_obj # AttributeType object
  attr_reader :default
  attr_reader :source_location
  
  ##
  #
  def initialize(services, id, type, jaba_type_obj, source_location)
    super(services, services.attr_definition_api)
    @id = id
    @type = type
    @jaba_type_obj = jaba_type_obj
    @source_location = source_location

    @default = nil
    @flags = []
    @help = nil
    
    @value_validator = nil
    @post_set = nil
    @make_handle = nil
    
    @properties = nil
    
    @type_obj = @services.get_attribute_type(@type)
    
    if @type_obj.init_attr_hook
      api_eval(&@type_obj.init_attr_hook)
    end
  end
  
  ##
  #
  def has_flag?(flag)
    @flags.index(flag) != nil
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
    adv = @type_obj.attr_def_validator
    if adv
      begin
        api_eval(&adv)
      rescue JabaError => e
        @services.jaba_error("'#{id}' attribute definition failed validation: #{e.raw_message}", callstack: [e.backtrace[0], @source_location.join(':')]) # TODO: wrap up a bit nicer so join not required
      end
    end
    if @default
      vv = @type_obj.value_validator
      if vv
        begin
          api_eval(@default, &vv)
        rescue JabaError => e
          @services.jaba_error("'#{id}' attribute definition failed validation: #{e.raw_message}", callstack: [e.backtrace[0], @source_location.join(':')]) # TODO: wrap up a bit nicer so join not required
        end
      end
    end
  end
  
  Property = Struct.new(:value)
  
  ##
  #
  def add_property(id, val=nil)
    if @properties.nil?
      @properties = {}
    end
    @properties[id] = Property.new(val)
  end

  ##
  #
  def get_property(id)
    p = @properties ? @properties[id] : nil
    if !p
      @services.jaba_error("'#{id}' property not defined")
    end
    p
  end
  
  ##
  #
  def handle_property(id, val)
    p = get_property(id)
    if val.nil?
      return p.value
    else
      p.value = val
    end
  end
  
end

##
# eg project/workspace/category etc.
#
class JabaType < JabaAPIObject

  attr_reader :type
  attr_reader :generators
  
  ##
  #
  def initialize(services, type_id)
    super(services, services.jaba_type_api)
    @type = type_id
    @attribute_defs = []
    @generators = []
  end
  
  ##
  #
  def define_attr(id, type: nil, &block)
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
    ad.api_eval(&block)
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
