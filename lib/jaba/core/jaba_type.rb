# frozen_string_literal: true

##
#
module JABA

  using JABACoreExt
  
  ##
  #
  class JabaObject
    
    attr_reader :services
    
    ##
    #
    def initialize(services)
      @services = services
    end
    
    ##
    #
    def eval_obj(context)
      self
    end
    
    ##
    #
    def jaba_error(msg, **options)
      @services.jaba_error(msg, **options)
    end
    
    ##
    #
    def eval_definition(args = nil, context: :definition, &block)
      return if !block_given?
      if !args.nil?
        eval_obj(context).instance_exec(args, &block)
      else
        eval_obj(context).instance_eval(&block)
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
        
        n_expected = df.block.arity
        n_actual = args ? Array(args).size : 0
        
        if n_actual != n_expected
          @services.jaba_error("shared definition '#{id}' expects #{n_expected} arguments but #{n_actual} were passed")
        end
        
        eval_definition(args, &df.block)
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
  class JabaTypeAPI < BasicObject

    include DefinitionCommon

    ##
    # Define a new attribute.
    #
    def attr(id, **options, &block)
      @jaba_type.define_attr(id, :single, **options, &block)
    end
    
    ##
    #
    def attr_array(id, **options, &block)
      @jaba_type.define_attr(id, :array, **options, &block)
    end
    
    ##
    #
    def dependencies(*deps)
      @jaba_type.set_property(:dependencies, deps.flatten)
    end

    ##
    #
    def type
      @jaba_type.type
    end

    ##
    #
    def initialize(jaba_type)
      @jaba_type = jaba_type
      @obj = jaba_type
    end

  end

  ##
  # eg project/workspace/category etc.
  #
  class JabaType < JabaObject

    include PropertyMethods
    
    attr_reader :type
    attr_reader :attribute_defs
    attr_reader :dependencies
    attr_reader :generator
    
    ##
    #
    def initialize(services, info)
      super(services)
      @type = info.type
      @super_type = info.options[:extend]
      @attribute_defs = []
      @attribute_def_lookup = {}
      @dependencies = []
      
      @definition_interface = JabaTypeAPI.new(self)

      @generator = nil
      gen_classname = "JABA::#{type.to_s.capitalize_first}Generator"
      
      if Object.const_defined?(gen_classname)
        generator_class = Module.const_get(gen_classname)
        if generator_class.superclass != Generator
          raise "#{generator_class} must inherit from Generator class"
        end
        @services.log "Creating #{generator_class}"
        @generator = generator_class.new(@services, self)
        @generator.init if @generator.respond_to?(:init)
      end
      
      eval_definition(&info.block)
    end
    
    ##
    #
    def eval_obj(context)
      case context
      when :definition
        @definition_interface
      when :internal
        self
      else
        raise "invalid context #{context}"
      end
    end

    ##
    #
    def to_s
      @type.to_s
    end
    
    ##
    #
    def define_attr(id, variant, type: nil, &block)
      if !(id.is_a?(Symbol) || id.is_a?(String))
        @services.jaba_error("'#{id}' attribute id must be specified as a symbol or string")
      end
      id = id.to_sym
      if get_attr_def(id, fail_if_not_found: false)
        @services.jaba_error("'#{id}' attribute multiply defined")
      end
      ad = AttributeDefinition.new(@services, id, type, variant, self, caller(2, 1)[0])
      ad.eval_definition(&block)
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
    def init
      # Convert super type id to object handle
      #
      @super_type = @services.get_jaba_type(@super_type) if @super_type

      @attribute_defs.each(&:init)
    end
    
    ##
    #
    def resolve_dependencies
      # Convert dependencies specified as ids to jaba type objects
      #
      @dependencies&.uniq!
      @dependencies&.map! {|dep| @services.get_jaba_type(dep)}
    end
    
  end

end
