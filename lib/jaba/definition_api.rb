module JABA

  ##
  #
  class APIBase < BasicObject

    ##
    # Include one or more shared definitions in this one.
    #
    def include(*shared_definition_ids, args: nil)
      @obj.include_shared(shared_definition_ids, args)
    end
    
    ##
    #
    def raise(msg)
      @obj.services.jaba_error(msg)
    end

    ##
    #
    def puts(str)
      ::Kernel.puts(str)
    end
    
    ##
    # Internal use only.
    #
    def __set_obj(o)
      @obj = o
    end
    
  end

  require_relative 'extension_api'

  ##
  # API for creating instances of Jaba types.
  #
  class TopLevelAPI < APIBase
    
    undef_method :include
    include TopLevelExtensionAPI
    
    ##
    # Define a project.
    #
    def project(id, **options, &block)
      @obj.define_instance(:project, id, **options, &block)
    end
    
    ##
    # Define a workspace.
    #
    def workspace(id, **options, &block)
      @obj.define_instance(:workspace, id, **options, &block)
    end
    
    ##
    # Define a category.
    #
    def category(id, **options, &block)
      @obj.define_instance(:category, id, **options, &block)
    end
    
    ##
    # Define definition to be included by other definitions.
    #
    def shared(id, **options, &block)
      @obj.define_instance(:shared, id, **options, &block)
    end
    
    ##
    #
    def text(id, **options, &block)
      @obj.define_instance(:text, id, **options, &block)
    end
    
    ##
    #
    def method_missing(type, id, **options, &block)
      @obj.define_instance(type, id, **options, &block)
    end
    
  end

  ##
  # TODO: make a list of reserved words that could come into use in the future and protect against usage
  #
  class JabaNodeAPI < APIBase

    ##
    #
    def id
      @obj.id
    end
    
    ##
    #
    def generate(&block)
      @obj.define_hook(:generate, allow_multiple: true, &block)
    end
    
    ##
    #
    def lambda(&block)
      ::Kernel.lambda(&block)
    end
    
    ##
    # Clears any previously set values. Sets single attribute values to nil and clears array attributes.
    #
    def wipe(*attr_ids)
      @obj.wipe_attrs(attr_ids)
    end
    
    ##
    #
    def method_missing(attr_id, *args, **key_value_args, &block)
      @obj.handle_attr(attr_id, ::Kernel.caller(1, 1), *args, **key_value_args, &block)
    end
    
  end

end
