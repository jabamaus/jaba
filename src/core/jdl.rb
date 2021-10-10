module JABA

  ##
  #
  class JDL_Base < BasicObject

    ##
    # Assist ruby with constant lookup. Needed when type plugins are declared inline in jaba files and the implementation uses standard ruby classes.
    #
    def self.const_missing(name)
      ::Object.const_get(name)
    end

    # Hack to fix issues when debugging. When ruby_debug_ide evals certain objects instance variables and they contain
    # references to the JDL Objects it calls methods on it that don't exist (because BasicObject is a blank slate with barely any methods).
    # These method calls then go through to method_missing and are interpreted as instances of jaba types, meaning program
    # state is being changed as a consequence of being debugged. To prevent this, implement nil? and make it raise an error. nil?
    # is the first method ruby_debug_ide calls. The exception prevents further calls and 'BasicObject' is displayed in the debugger.
    #
    if ::JABA.ruby_debug_ide?
      def to_s
        'BasicObject'
      end
      
      def nil?
        ::Kernel.raise to_s
      end

      def local_variables
        []
      end
    end

  private

    def initialize(obj) = @obj = obj

  end

  ##
  #
  module CommonAPI
    
    ##
    #
    def jdl_fail(msg)
      JABA.error(msg)
    end

    ##
    #
    def jdl_warn(msg)
      jaba_warn(msg)
    end

    ##
    #
    def jdl_print(msg)
      ::Kernel.print(msg)
    end

    ##
    #
    def jdl_puts(msg)
      ::Kernel.puts(msg)
    end

  end

  ##
  #
  module TopLevelAPI

    include CommonAPI

    ##
    # Include another .jaba file or directory containing .jaba files.
    #
    def jdl_include(...)
      @load_manager.process_include(:jaba_file, ...)
    end

    ##
    #
    def jdl_on_included(...)
      @load_manager.on_included(...)
    end

    ##
    # Include a jaba file or files from jaba's grab bag.
    #
    def jdl_grab(...)
      @load_manager.process_include(:grab_bag, ...)
    end

    ##
    # EXTENSION API
    #
    def jdl_type(...)
      define(:type, ...)
    end

    ##
    #
    def jdl_method_missing(...)
      define(:instance, ...)
    end

    ##
    #
    def jdl_shared(...)
      define(:shared, ...)
    end
    
    ##
    #
    def jdl_defaults(...)
      define(:defaults, ...)
    end

    ##
    # EXTENSION API
    #
    def jdl_translator(...)
      define(:translator, ...)
    end

    ##
    # EXTENSION API
    #
    def jdl_open_type(...)
      open(:type, ...)
    end

    ##
    # EXTENSION API
    #
    def jdl_open_instance(...)
      open(:instance, ...)
    end

    ##
    # EXTENSION API
    #
    def jdl_open_globals(...)
      open(:instance, 'globals|globals', ...)
    end

    ##
    # EXTENSION API
    #
    def jdl_open_translator(...)
      open(:translator, ...)
    end

    ##
    # EXTENSION API
    #
    def jdl_open_shared(...)
      open(:shared, ...)
    end

    ##
    #
    def jdl_all_instance_ids(...)
      get_node_manager(...).top_level_ids
    end

    ##
    #
    def jdl_glob(...)
      @file_manager.jdl_glob(...)
    end

  end

  ##
  #
  module ObjectAPI

    ##
    #
    def jdl_id = defn_id

    ##
    #
    def jdl_include(...)
      include_shared(...)
    end

    ##
    # The directory this definition is in.
    #
    def jdl___dir__ = source_dir

    ##
    # Returns all the ids of all defined instances of the given type. Can be useful when populating choice attribute items.
    # The type must be defined before this is called, which can be achieved by adding a dependency.
    #
    def jdl_all_instance_ids(jaba_type_id)
      @services.jdl_all_instance_ids(jaba_type_id)
    end

  end

  ##
  #
  module TypeDefinitionAPI

    include CommonAPI
    include ObjectAPI

    ##
    # Set title for the type. Required. Will appear in generated reference manual.
    #
    def jdl_title(val)
      set_property_from_jdl(:title, val)
    end

    ##
    # Flag type as singleton.
    #
    def jdl_singleton(val)
      set_property_from_jdl(:singleton, val)
    end

    ##
    # Add a help note for this type. Multiple can be added. Will appear in generated reference manual.
    #
    def jdl_note(val)
      set_property_from_jdl(:notes, val)
    end

    ##
    # Define a new attribute.
    #
    def jdl_attr(id, type: nil, jaba_type: nil, &block)
      define_attr(id, :single, type: type, jaba_type: jaba_type, &block)
    end
    
    ##
    # Define a new array attribute.
    #
    def jdl_attr_array(id, type: nil, jaba_type: nil, &block)
      define_attr(id, :array, type: type, jaba_type: jaba_type, &block)
    end
    
    ##
    # Define a new hash attribute.
    #
    def jdl_attr_hash(id, type: nil, key_type: nil, jaba_type: nil, &block)
      define_attr(id, :hash, type: type, key_type: key_type, jaba_type: jaba_type, &block)
    end

    ##
    #
    def jdl_dependencies(*deps)
      set_property_from_jdl(:dependencies, deps)
    end

    ##
    # EXTENSION API
    #
    def jdl_plugin(id, &block)
      set_property_from_jdl(:plugin, id, &block)
    end

  end

  ##
  #
  module AttributeDefinitionAPI

    include CommonAPI
    include ObjectAPI

    ##
    # Set title of attribute. Required. Will appear in generated reference manual.
    #
    def jdl_title(val = nil)
      set_property_from_jdl(:title, val)
    end

    ##
    # Add a help note for the attribute. Multiple can be added. Will appear in generated reference manual.
    #
    def jdl_note(val)
      set_property_from_jdl(:notes)
    end
    
    ##
    # Add usage example. Will appear in generated reference manual.
    #
    def jdl_example(val)
      set_property_from_jdl(:examples, val)
    end

    ##
    # Set any number of flags to control the behaviour of the attribute.
    #
    def jdl_flags(*flags)
      set_property_from_jdl(:flags, flags)
    end
    
    ##
    # Set attribute default value. Can be specified as a value or a block.
    #
    def jdl_default(val = nil, &block)
      set_property_from_jdl(:default, val, &block)
    end

    ##
    #
    def jdl_default_set? = default_set?
    
    ##
    #
    def jdl_flag_options(*options)
      set_property_from_jdl(:flag_options, options)
    end

    ##
    # Specify an option that takes a value.
    #
    # attr :myattr do
    #   value_option :group, required: true, items [:a, :b, :c]
    # end
    # 
    # would be called like this in definitions:
    #
    # myattr 'value', group: :a
    #
    # And the presence of the :group option and its value would be validated.
    #
    def jdl_value_option(id, required: false, items: [])
      add_value_option(id, required, items)
    end
    
    ##
    # Called for single value attributes and each element of array attributes.
    #
    def jdl_validate(&block)
      set_property_from_jdl(:validate, &block)
    end
    
    ##
    # Use to validate the key of a hash attribute. Cannot be used with single value of array attributes.
    #
    def jdl_validate_key(&block)
      set_property_from_jdl(:validate_key, &block)
    end

    ##
    #
    def jdl_on_set(&block)
      set_property_from_jdl(:on_set, &block)
    end
    
    ##
    # Returns attribute type id, eg :bool, :string, :choice, :ref, :file etc
    #
    def jdl_type = type_id

    ##
    # Returns :single, :array or :hash
    #
    def jdl_variant = variant

    ##
    #
    def jdl_single? = single?

    ##
    #
    def jdl_array? = array?

    ##
    #
    def jdl_hash? = hash?

    ##
    #
    def jdl_has_flag?(flag) = has_flag?(flag)

    ##
    # Access the attributes of the globals node.
    #
    def jdl_globals = services.globals_node.api

    ##
    # Access node attributes of dependencies which have already been created before this type was initialised.
    #
    def jdl_instances(type)
      services.get_nodes_of_type(type)
    end

    ##
    #
    def jdl_method_missing(id, val = nil, &block)
      handle_property_from_jdl(id, val, &block)
    end

  end

  ##
  #
  module NodeAPI
  
    include CommonAPI
    include ObjectAPI

    ##
    # Access the attributes of the globals node.
    #
    def jdl_globals
      services.globals_node.api
    end

    ##
    # Clears any previously set values. Sets single attribute values to nil and clears array attributes.
    #
    def jdl_wipe(*attr_ids)
      wipe_attrs(attr_ids)
    end 

    ##
    #
    def jdl_generate(&block)
      set_property_from_jdl(:generate, &block)
    end

    ##
    #
    def jdl_method_missing(...)
      handle_attr_from_jdl(...)
    end

  end

  ##
  #
  module TranslatorAPI

    include CommonAPI
    include ObjectAPI

    ##
    #
    def jdl_method_missing(...)
      handle_attr_from_jdl(...)
    end

  end

  const_set('JDL_TopLevel', make_api_class(TopLevelAPI))
  const_set('JDL_Type', make_api_class(TypeDefinitionAPI))
  const_set('JDL_AttributeDefinition', make_api_class(AttributeDefinitionAPI))
  const_set('JDL_Node', make_api_class(NodeAPI))
  const_set('JDL_Translator', make_api_class(TranslatorAPI))

end
