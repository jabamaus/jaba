module JABA

  class JDL_Base < BasicObject
    include ::RdbgBasicObjectMixin
    def self.const_missing(name) = ::Object.const_get(name)
  private
    def initialize(obj) = @obj = obj
  end

  module CommonAPI
    def jdl_fail(msg) = JABA.error(msg)
    def jdl_warn(msg) = jaba_warn(msg)
    def jdl_print(msg) = ::Kernel.print(msg)
    def jdl_puts(msg) = ::Kernel.puts(msg)
  end

  module TopLevelAPI
    include CommonAPI

    # Include another .jaba file or directory containing .jaba files.
    #
    def jdl_include(...) = @load_manager.process_include(:jaba_file, ...)
    def jdl_on_included(...) = @load_manager.on_included(...)

    # Include a jaba file or files from jaba's grab bag.
    #
    def jdl_grab(...) = @load_manager.process_include(:grab_bag, ...)
    def jdl_type(...) = define(:type, ...)
    def jdl_method_missing(...) = define(:instance, ...)
    def jdl_shared(...) = define(:shared, ...)
    def jdl_defaults(...) = define(:defaults, ...)
    def jdl_translator(...) = define(:translator, ...)
    def jdl_open_type(...) = open(:type, ...)
    def jdl_open_instance(...) = open(:instance, ...)
    def jdl_open_globals(...) = open(:instance, 'globals|globals', ...)
    def jdl_open_translator(...) = open(:translator, ...)
    def jdl_open_shared(...) = open(:shared, ...)
    def jdl_all_instance_ids(...) = get_node_manager(...).top_level_ids
    def jdl_glob(spec, relative: false) = @file_manager.jdl_glob(spec, relative: relative)
  end

  module ObjectAPI
    def jdl_id = defn_id
    # Include a shared definition. Any arguments passed are expected to be in keyword form.
    def jdl_include(...) = include_shared(...)

    # The directory this definition is in.
    #
    def jdl___dir__ = source_dir

    # Returns all the ids of all defined instances of the given type. Can be useful when populating choice attribute items.
    # The type must be defined before this is called, which can be achieved by adding a dependency.
    #
    def jdl_all_instance_ids(jaba_type_id) = @services.jdl_all_instance_ids(jaba_type_id)
  end

  module TypeDefinitionAPI
    include CommonAPI
    include ObjectAPI

    # Set title for the type. Required. Will appear in generated reference manual.
    #
    def jdl_title(val) = set_property_from_jdl(:title, val)

    # Flag type as singleton.
    #
    def jdl_singleton(val) = set_property_from_jdl(:singleton, val)

    # Add a help note for this type. Multiple can be added. Will appear in generated reference manual.
    #
    def jdl_note(val) = set_property_from_jdl(:notes, val)

    # Define a new attribute.
    #
    def jdl_attr(id, type: nil, jaba_type: nil, &block)
      define_attr(id, :single, type: type, jaba_type: jaba_type, &block)
    end
    
    # Define a new array attribute.
    #
    def jdl_attr_array(id, type: nil, jaba_type: nil, &block)
      define_attr(id, :array, type: type, jaba_type: jaba_type, &block)
    end
    
    # Define a new hash attribute.
    #
    def jdl_attr_hash(id, type: nil, key_type: nil, jaba_type: nil, &block)
      define_attr(id, :hash, type: type, key_type: key_type, jaba_type: jaba_type, &block)
    end

    def jdl_dependencies(*deps) = set_property_from_jdl(:dependencies, deps)
    def jdl_plugin(id, &block) = set_property_from_jdl(:plugin, id, &block)
  end

  module AttributeDefinitionAPI
    include CommonAPI
    include ObjectAPI

    # Set title of attribute. Required. Will appear in generated reference manual.
    #
    def jdl_title(val = nil) = set_property_from_jdl(:title, val)
      
    # Add a help note for the attribute. Multiple can be added. Will appear in generated reference manual.
    #
    def jdl_note(val) = set_property_from_jdl(:notes, val)
    
    # Add usage example. Will appear in generated reference manual.
    #
    def jdl_example(val) = set_property_from_jdl(:examples, val)

    # Set any number of flags to control the behaviour of the attribute.
    #
    def jdl_flags(*flags) = set_property_from_jdl(:flags, flags)
    
    # Set attribute default value. Can be specified as a value or a block.
    #
    def jdl_default(val = nil, &block) = set_property_from_jdl(:default, val, &block)

    def jdl_default_set? = default_set?

    def jdl_flag_options(*options) = set_property_from_jdl(:flag_options, options)

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
    
    # Called for single value attributes and each element of array attributes.
    #
    def jdl_validate(&block) = set_property_from_jdl(:validate, &block)
    
    # Use to validate the key of a hash attribute. Cannot be used with single value of array attributes.
    #
    def jdl_validate_key(&block) = set_property_from_jdl(:validate_key, &block)

    def jdl_on_set(&block) = set_property_from_jdl(:on_set, &block)
    
    # Returns attribute type id, eg :bool, :string, :choice, :ref, :file etc
    #
    def jdl_type = type_id

    # Returns :single, :array or :hash
    #
    def jdl_variant = variant
    def jdl_single? = single?
    def jdl_array? = array?
    def jdl_hash? = hash?
    def jdl_has_flag?(flag) = has_flag?(flag)

    # Access the attributes of the globals node.
    #
    def jdl_globals = services.globals_node.api

    # Access node attributes of dependencies which have already been created before this type was initialised.
    #
    def jdl_instances(type) = services.get_nodes_of_type(type)

    def jdl_method_missing(id, val = nil, &block)
      handle_property_from_jdl(id, val, &block)
    end
  end

  module NodeAPI
    include CommonAPI
    include ObjectAPI

    # Access the attributes of the globals node.
    #
    def jdl_globals = services.globals_node.api

    def jdl_glob(spec, relative: false) = jdl_glob(spec, relative: relative)
    
      # Clears any previously set values. Sets single attribute values to nil and clears array attributes.
    #
    def jdl_wipe(*attr_ids) = wipe_attrs(attr_ids)
    def jdl_generate(&block) = set_property_from_jdl(:generate, &block)
    def jdl_method_missing(...) = handle_attr_from_jdl(...)
  end

  module TranslatorAPI
    include CommonAPI
    include ObjectAPI

    def jdl_method_missing(...) = handle_attr_from_jdl(...)
  end

  const_set('JDL_TopLevel', make_api_class(TopLevelAPI))
  const_set('JDL_Type', make_api_class(TypeDefinitionAPI))
  const_set('JDL_AttributeDefinition', make_api_class(AttributeDefinitionAPI))
  const_set('JDL_Node', make_api_class(NodeAPI))
  const_set('JDL_Translator', make_api_class(TranslatorAPI))
end
