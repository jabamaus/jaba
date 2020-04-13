# frozen_string_literal: true

##
#
module JABA

  using JABACoreExt
  
  ##
  # eg project/workspace/category etc.
  #
  class JabaType < JabaObject

    include PropertyMethods
    
    attr_reader :type_id  # eg :text, :cpp, :platform
    attr_reader :attribute_defs
    attr_reader :dependencies
    attr_reader :generator
    
    ##
    #
    def initialize(services, info)
      super(services, JabaTypeAPI.new(self))
      @type_id = info.type_id
      @super_type = info.options[:extend]
      @attribute_defs = []
      @attribute_def_lookup = {}
      @dependencies = []
      @generator = nil

      gen_classname = "JABA::#{type_id.to_s.capitalize_first}Generator"
      
      if Object.const_defined?(gen_classname)
        generator_class = Module.const_get(gen_classname)
        if generator_class.superclass != Generator
          raise "#{generator_class} must inherit from Generator class"
        end
        @services.log "Creating #{generator_class}"
        @generator = generator_class.new(@services, self)
        @generator.init if @generator.respond_to?(:init)
      end
      
      eval_api_block(&info.block)
    end

    ##
    # For ease of debugging.
    #
    def to_s
      @type_id.to_s
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
      ad = JabaAttributeDefinition.new(@services, id, type, variant, self, caller(2, 1)[0])
      ad.eval_api_block(&block)
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
    def iterate_attr_defs(&block)
      @attribute_defs.each(&block)
      @super_type&.iterate_attr_defs(&block)
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
