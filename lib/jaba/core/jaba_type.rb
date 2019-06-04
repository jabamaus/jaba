# frozen_string_literal: true

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
    def api_eval(args = nil, &block)
      @api.__set_obj(self)
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
    
    ##
    #
    def include_shared(ids, args)
      ids.each do |id|
        df = @services.get_definition(:shared, id, fail_if_not_found: false)
        if !df
          @services.jaba_error("Shared definition '#{id}' not found")
        end
        
        n_expected = df.block.arity
        n_actual = args ? Array(args).size : 0
        
        if n_actual != n_expected
          @services.jaba_error("shared definition '#{id}' expects #{n_expected} arguments but #{n_actual} were passed")
        end
        
        api_eval(args, &df.block)
      end
    end
    
    ##
    #
    def set_var(var_name, val = nil, &block)
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
    def handle_property(id, val, &block)
      if !instance_variable_defined?("@#{id}")
        @services.jaba_error("'#{id}' property not defined")
      end
      if val.nil?
        return instance_variable_get("@#{id}")
      else
        set_var(id, val, &block)
      end
    end
    
    ##
    # TODO: test
    def define_hook(id, allow_multiple: false, &block)
      if allow_multiple
        instance_variable_get("@#{id}_hooks") << block
      else
        hook = "@#{id}_hook"
        if instance_variable_get(hook)
          @services.jaba_error("'#{id}' hook already set")
        end
        instance_variable_set(hook, block)
      end
    end
    
  end

  ##
  #
  class AttributeType < JabaAPIObject

    attr_reader :type
    attr_reader :init_attr_def_hook
    attr_reader :validate_attr_def_hook
    attr_reader :validate_value_hook
    
    ##
    #
    def initialize(services, type_id)
      super(services, services.attr_type_api)
      @type = type_id
      @init_attr_def_hook = nil
      @validate_attr_def_hook = nil
      @validate_value_hook = nil
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
    def initialize(services, id, type, is_array, jaba_type_obj, source_location)
      super(services, services.attr_definition_api)
      @id = id
      @type = type
      @is_array = is_array
      @jaba_type_obj = jaba_type_obj
      @source_location = source_location

      @default = nil
      @flags = []
      @help = nil
      
      @validate_hook = nil
      @post_set_hook = nil
      @make_handle_hook = nil
      
      @type_obj = @services.get_attribute_type(@type)
      
      if @type_obj.init_attr_def_hook
        api_eval(&@type_obj.init_attr_def_hook)
      end
    end
    
    ##
    #
    def array?
      @is_array
    end
    
    ##
    #
    def has_flag?(flag)
      @flags.include?(flag)
    end
    
    ##
    #
    def init
      hook = @type_obj.validate_attr_def_hook
      if hook
        begin
          api_eval(&hook)
        rescue JabaError => e
          @services.jaba_error("'#{id}' attribute definition failed validation: #{e.raw_message}",
                               callstack: [e.backtrace[0], @source_location.join(':')]) # TODO: improve
        end
      end
      
      if @default
        hook = @type_obj.validate_value_hook
        if hook
          begin
            api_eval(@default, &hook)
          rescue JabaError => e
            @services.jaba_error("'#{id}' attribute definition failed validation: #{e.raw_message}",
                                 callstack: [e.backtrace[0], @source_location.join(':')]) # TODO: improve
          end
        end
      end
    end
    
  end

  ##
  # eg project/workspace/category etc.
  #
  class JabaType < JabaAPIObject

    attr_reader :type
    attr_reader :attribute_defs
    
    ##
    #
    def initialize(services, type_id, super_type_id)
      super(services, services.jaba_type_api)
      @type = type_id
      @super_type = super_type_id
      @attribute_defs = []
      @attribute_def_lookup = {}
      @build_nodes_hook = nil
    end
    
    ##
    #
    def define_attr(id, type: nil, array: false, &block)
      if !id.is_a?(Symbol)
        @services.jaba_error("'#{id}' attribute id must be specified as a symbol")
      end
      if !block_given?
        @services.jaba_error("'#{id}' attribute requires a block")
      end
      if get_attr_def(id, fail_if_not_found: false)
        @services.jaba_error("'#{id}' attribute multiply defined")
      end
      ad = AttributeDefinition.new(@services, id, type, array, self, block.source_location)
      ad.api_eval(&block)
      @attribute_defs << ad
      @attribute_def_lookup[id] = ad
      ad
    end
    
    ##
    #
    def get_attr_def(id, fail_if_not_found: true)
      a = @attribute_def_lookup[id]
      if !a && fail_if_not_found
        @services.jaba_error("'#{id}' attribute definition not found in '#{type}'")
      end
      a
    end
    
    ##
    #
    def iterate_attrs(mask, &block)
      @attribute_defs.each do |ad|
        if !mask || mask.include?(ad.id)
          yield ad
        end
      end
      @super_type&.iterate_attrs(mask, &block)
    end
    
    ##
    #
    def make_node(attrs_mask: nil, parent: nil)
      jn = JabaNode.new(@services, self, @current_def_data.id, attrs_mask, parent, @current_def_data.block.source_location)
      yield jn if block_given?
      jn.api_eval(&@current_def_data.block)
      jn.post_create
      jn
    end
    
    ##
    #
    def init
      # Convert super type id to object handle
      #
      @super_type = @services.get_jaba_type(@super_type) if @super_type
      @attribute_defs.each(&:init)
    end
    
    ##
    #
    def build_nodes(def_data)
      @current_def_data = def_data
      if @build_nodes_hook
        result = instance_eval(&@build_nodes_hook) # TODO: what api should build_nodes hook be targeting?
        if result.nil? || !result.is_a?(Array) || result.empty? || !result[0].is_a?(JabaNode)
          @services.jaba_error("'build_nodes' hook must return an array of nodes") # TODO: test this
        end
        return result
      else
        return [make_node]
      end 
    end
    
  end

end
