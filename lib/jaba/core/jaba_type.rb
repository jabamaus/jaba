# frozen_string_literal: true

##
#
module JABA

  using JABACoreExt
  
  ##
  #
  class JabaType < JDL_Object

    include PropertyMethods

    # The type id given to the jaba type in define() method, whether a top level type or a subtype.
    # Contrast this with defn_id which will return the top level type's id even if it is called
    # on a subtype.
    #
    attr_reader :handle
    attr_reader :top_level_type
    attr_reader :attribute_defs

    ##
    #
    def initialize(services, defn_id, src_loc, handle, top_level_type)
      super(services, defn_id, src_loc, JDL_Type.new(self))

      @handle = handle
      @top_level_type = top_level_type
      @attribute_defs = []
    end

    ##
    #
    def to_s
      @handle.to_s
    end

    ##
    #
    def define_attr(id, variant, type: nil, key_type: nil, &block)
      services.log "  Defining '#{id}' attribute [variant=#{variant}, type=#{type}]"
      
      if key_type && variant != :hash
        jaba_error("Only attr_hash supports :key_type argument")
      end
      
      validate_id(id)
      id = id.to_sym
      
      ad = JabaAttributeDefinition.new(@services, id, caller_locations(2, 1)[0], block, type, key_type, variant, self)
      @attribute_defs << ad

      top_level_type.register_attr_def(id, ad)
      ad  
    end

    ##
    #
    def define_sub_type(id, &block)
      jaba_error("Sub type '#{handle.inspect_unquoted}' cannot have another subtype '#{id.inspect_unquoted}'")
    end

    ##
    #
    def validate_id(id)
      if !(id.symbol? || id.string?) || id !~ /^[a-zA-Z0-9_\?]+$/
        jaba_error("'#{id}' is an invalid id. Must be an alphanumeric string or symbol " \
          "(underscore permitted), eg :my_id or 'my_id'")
      end
    end

  end

  ##
  # eg project/workspace/category etc.
  #
  class TopLevelJabaType < JabaType

    attr_reader :title
    attr_reader :notes
    attr_reader :singleton
    attr_reader :generator
    attr_reader :defaults_definition
    attr_reader :dependencies
    attr_reader :all_attr_defs_sorted
    attr_reader :open_sub_type_defs

    ##
    #
    def initialize(services, defn_id, src_loc, block, handle, generator)
      super(services, defn_id, src_loc, handle, self)

      @generator = generator
      @defaults_definition = services.get_defaults_definition(@defn_id)

      @all_attr_defs = {}
      @sub_types = []
      @open_sub_type_defs = []

      define_property(:title)
      define_array_property(:notes)
      define_property(:singleton)
      define_array_property(:dependencies) # TODO: validate explicitly specified deps

      set_property(:notes, "Manages attribute definitions for '#{@defn_id}' type")

      if block
        eval_jdl(&block)
      end

      validate

      @title.freeze
      @notes.freeze
      @singleton.freeze
    end

    ##
    #
    def define_sub_type(id, &block)
      # TODO: check for multiply defined sub types
      
      # Sub types share the top level defintion block info rather than having the info of their local block.
      # This is because sub types are very self contained and are not important to the rest of the system.
      # When something wants to ask it its definition id it is more helpful to return the id of the
      # top level definition than its local id, which nothing external to JabaType is interested in.
      #
      st = JabaType.new(@services, defn_id, caller_locations(2, 1)[0], id, self)
      if block_given?
        st.eval_jdl(&block)
      end
      
      @sub_types << st
      st
    end

    ##
    #
    def open_sub_type(subtype_id, &block)
      @open_sub_type_defs << services.make_definition(subtype_id, block, caller_locations(2, 1)[0])
    end

    ##
    #
    def get_sub_type(id)
      st = @sub_types.find{|st| st.handle == id}
      if !st
        jaba_error("'#{id.inspect_unquoted}' sub type not found in '#{@defn_id.inspect_unquoted}' top level type")
      end
      st
    end

    ##
    #
    def get_attr_def(id)
      @all_attr_defs[id]
    end

    ##
    #
    def register_attr_def(id, attr_def)
      if @all_attr_defs.key?(id)
        attr_def.jaba_error("'#{id}' attribute multiply defined in '#{defn_id}'")
      end
      @all_attr_defs[id] = attr_def
    end

    ##
    #
    def validate
      # Insist on the attribute having a title, unless running unit tests or in barebones mode. Barebones mode
      # is useful for testing little jaba snippets where adding titles would be cumbersome.
      #
      if @title.nil? && !JABA.running_tests? && !services.input.barebones
        jaba_error("Requires a title", errline: src_loc)
      end

    rescue JDLError => e
      jaba_error("'#{defn_id}' type failed validation: #{e.raw_message}", callstack: e.backtrace)
    end

    ##
    #
    def post_create
      @attribute_defs.sort_by! {|ad| ad.defn_id}

      # Register referenced attributes
      #
      to_register = []
      @all_attr_defs.each do |id, attr_def|
        if attr_def.reference?
          rt_id = attr_def.object_type
          if rt_id != defn_id
            jt = attr_def.services.get_top_level_jaba_type(rt_id)
            jt.attribute_defs.each do |d|
              if d.has_flag?(:expose)
                to_register << d
              end
            end
          end
        end
      end

      # Store sorted list of all attributes (including sub_types). Do this before referenced attributes
      # are registered so list only contains attributes from this jaba type.
      # Used in reference manual.
      #
      @all_attr_defs_sorted = @all_attr_defs.values.sort_by {|ad| ad.defn_id}
   
      to_register.each{|d| register_attr_def(d.defn_id, d)}

      # Convert dependencies specified as ids to jaba type objects
      #
      @dependencies.uniq!
      @dependencies.map! {|dep| services.get_top_level_jaba_type(dep)}
    end

    ##
    #
    def reference_manual_page(ext: '.html')
      "jaba_type_#{defn_id}#{ext}"
    end

  end

end
