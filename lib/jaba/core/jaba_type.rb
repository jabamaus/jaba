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
    
    attr_reader :handle
    attr_reader :attribute_defs
    attr_reader :dependencies
    attr_reader :generator
    
    ##
    #
    def initialize(services, definition, handle, generator)
      super(services, definition, JabaTypeAPI.new(self))

      @handle = handle
      @attribute_defs = []
      @attribute_def_lookup = {}
      @generator = generator

      define_property(:help)
      define_array_property(:dependencies)
    end

    ##
    #
    def define_attr(id, variant, type: nil, &block)
      if @generator
        st_handle = @generator.sub_type(id)
        if st_handle
          sub_type = @services.get_jaba_type(st_handle, fail_if_not_found: false)
          if sub_type.nil?
            sub_type = @services.make_type(st_handle, @definition, sub_type: true)
            @dependencies << st_handle
          end
          return sub_type.make_attr_def(id, variant, type, &block)
        end
      end
      make_attr_def(id, variant, type, &block)
    end

    ##
    #
    def make_attr_def(id, variant, type, &block)
      @services.log "  Adding '#{id}' to '#{@handle}'"
      
      validate_id(id)
      id = id.to_sym
      
      if get_attr_def(id, fail_if_not_found: false)
        jaba_error("'#{id}' attribute multiply defined")
      end

      # TODO: caller will be wrong in the case of sub type
      db = JabaDefinition.new(id, block, caller(3, 1)[0])
      ad = JabaAttributeDefinition.new(@services, db, type, variant, self)
      
      @attribute_defs << ad
      @attribute_def_lookup[id] = ad

      ad
    end

    ##
    #
    def define_sub_type(id, &block)
      @services.make_type(id, @definition, sub_type: true, &block)
      @dependencies << id
    end

    ##
    #
    def to_s
      @handle.to_s
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
      @attribute_defs.each(&:init)
    end

    ##
    #
    def resolve_dependencies
      # Convert dependencies specified as ids to jaba type objects
      #
      @dependencies.uniq!
      @dependencies.map! {|dep| @services.get_jaba_type(dep)}
    end
    
  end

end
