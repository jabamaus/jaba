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
    
    attr_reader :attribute_defs
    attr_reader :dependencies
    attr_reader :generator
    attr_reader :defaults_block
    
    ##
    #
    def initialize(services, definition_id, block, defaults_block, generator)
      super(services, definition_id, JabaTypeAPI.new(self))
      @block = block
      @defaults_block = defaults_block
      @attribute_defs = []
      @attribute_def_lookup = {}
      @generator = generator

      define_property(:help)
      define_array_property(:dependencies)

      @services.register_jaba_type(self, definition_id)
    end

    ##
    #
    def to_s
      @definition_id.to_s
    end
    
    ##
    #
    def define_attr(id, variant, type: nil, &block)
      if @generator
        st_id = @generator.sub_type(id)
        if st_id
          jt = @services.get_jaba_type(st_id, fail_if_not_found: false)
          if jt.nil?
            jt = JabaType.new(@services, st_id, nil, @defaults_block, nil)
            @dependencies << st_id
            @services.register_additional_jaba_type(jt)
          end
          return jt.define_attr(id, variant, type: type, &block)
        end
      end

      validate_id(id)
      id = id.to_sym
      
      if get_attr_def(id, fail_if_not_found: false)
        jaba_error("'#{id}' attribute multiply defined")
      end
      # TODO: caller will be wrong in the case of custom type
      ad = JabaAttributeDefinition.new(@services, id, type, variant, self, caller(2, 1)[0])
      @attribute_defs << ad
      @attribute_def_lookup[id] = ad

      if block_given?
        ad.eval_api_block(&block)
      end

      ad
    end
    
    ##
    #
    def validate_id(id)
      if !(id.is_a?(Symbol) || id.is_a?(String)) || id !~ /^[a-zA-Z0-9_\?]+$/
        jaba_error("'#{id}' is an invalid id. Must be an alphanumeric string or symbol " \
          "(underscore permitted), eg :my_id or 'my_id'")
      end
    end

    ##
    #
    def get_attr_def(id, fail_if_not_found: true)
      a = @attribute_def_lookup[id]
      if !a
        if !a && fail_if_not_found
          jaba_error("'#{id}' attribute definition not found in '#{definition_id}'")
        end
      end
      a
    end
    
    ##
    #
    def init
      if @block
        eval_api_block(&@block)
      end
    end
    
    ##
    #
    def init_attrs
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
