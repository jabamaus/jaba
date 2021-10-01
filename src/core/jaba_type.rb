module JABA

  ##
  #
  class JabaType < JabaObject

    attr_reader :title
    attr_reader :notes
    attr_reader :singleton
    attr_reader :dependencies
    attr_reader :attribute_defs
    attr_reader :plugin

    ##
    #
    def initialize(services, defn_id, src_loc, block, open_defs)
      super(services, defn_id, src_loc, JDL_Type.new(self))

      @attribute_defs = [] # The type's actual attribute defs
      @attribute_def_lookup = {}
      @attribute_def_imported_lookup = {}
      @contained_types = []
      @attrs_evaluated = false

      define_single_property :title
      define_array_property :notes
      define_single_property :singleton
      define_array_property :dependencies # TODO: validate explicitly specified deps
      define_hash_property :plugin, type: :block

      set_property(:notes, "Manages attribute definitions for '#{@defn_id}' type")

      if block
        eval_jdl(&block)
      end

      if open_defs
        services.log "Opening #{defn_id} type"
        open_defs.each do |d|
          eval_jdl(&d.block)
        end
      end

      validate

      @title.freeze
      @notes.freeze
      @singleton.freeze
    end

    ##
    # Used in error messages.
    #
    def describe
      "'#{@defn_id}' type"
    end

    ##
    #
    def define_attr(id, variant, type: nil, key_type: nil, jaba_type: nil, &block)
      services.log "  Defining '#{id}' attribute [variant=#{variant}, type=#{type}]"
      
      if key_type && variant != :hash
        JABA.error("Only attr_hash supports key_type argument")
      end
      if jaba_type && type != :ref && type != :compound
        JABA.error("Only :compound and :ref attribute types supports jaba_type argument")
      end

      if (type == :ref || type == :compound) && !jaba_type
        JABA.error(":ref/:compound attribute types must specify jaba_type, eg 'add_attr type: :ref, jaba_type: :platform'")
      end
      
      validate_id(id)
      id = id.to_sym
      
      ad = case variant
      when :single
        JabaAttributeSingleDefinition.new(self, id, caller_locations(2, 1)[0], block, type, jaba_type)
      when :array
        JabaAttributeArrayDefinition.new(self, id, caller_locations(2, 1)[0], block, type, jaba_type)
      when :hash
        JabaAttributeHashDefinition.new(self, id, caller_locations(2, 1)[0], block, type, jaba_type, key_type)
      end
        
      register_attr_def(ad, :local)

      # If referenced jaba type specified and its not this type, add a dependency on the type. Used to dependency sort types
      # to ensure correct node instance creation order.
      #
      if jaba_type
        case type
        when :ref
          set_property(:dependencies, jaba_type)
        when :compound
          if jaba_type == defn_id
            JABA.error("Cannot contain own type")
          end
          @contained_types << jaba_type
        end
      end

      ad
    end

    ##
    #
    def get_attribute_def(id)
      @attribute_def_lookup[id]
    end

    ##
    #
    def post_create
      @contained_types.uniq!
      @contained_types.map!{|d| services.get_jaba_type(d)}
      @contained_types.each do |ct|
        @dependencies.concat(ct.dependencies)
      end
      @dependencies.uniq!
      @dependencies.map!{|d| services.get_jaba_type(d)}
    end

    ##
    #
    def eval_attr_defs
      return if @attrs_evaluated
      @attrs_evaluated = true
      @attribute_defs.each(&:eval_definition)

      # Register referenced attr defs
      #
      @attribute_defs.each do |attr_def|
        if attr_def.reference?
          rt_id = attr_def.ref_jaba_type
          if rt_id != defn_id
            jt = attr_def.services.get_jaba_type(rt_id)
            jt.attribute_defs.each do |d|
              if d.has_flag?(:expose)
                register_attr_def(d, :imported)
              end
            end
          end
        end
      end

      @attribute_defs.sort_by!{|ad| ad.defn_id}

      @contained_types.each do |ct|
        ct.eval_attr_defs
      end
    end

    ##
    #
    def reference_manual_page(ext: '.html')
      "jaba_type_#{defn_id}#{ext}"
    end

  private

    ##
    #
    def register_attr_def(ad, type)
      id = ad.defn_id
      case type
      when :local
        existing = @attribute_def_lookup[id]
        if existing
          JABA.error("'#{id}' attribute multiply defined in '#{defn_id}'. See previous at #{existing.src_loc.describe}", errobj: ad)
        end
        
        @attribute_defs << ad
        @attribute_def_lookup[id] = ad
      when :imported
        existing = @attribute_def_imported_lookup[id]
        if existing
          JABA.error("'#{id}' attribute multiply imported into '#{defn_id}'. See previous at #{existing.src_loc.describe}", errobj: ad)
        end

        @attribute_def_imported_lookup[id] = ad
      else
        JABA.error("Unrecognised type '#{type}'")
      end
    end

    ##
    #
    def validate_id(id)
      if !(id.symbol? || id.string?) || id !~ /^[a-zA-Z0-9_\?]+$/
        JABA.error("'#{id}' is an invalid id. Must be an alphanumeric string or symbol " \
          "(underscore permitted), eg :my_id or 'my_id'")
      end
    end

    ##
    #
    def validate
      # Insist on the attribute having a title, unless running unit tests or in barebones mode. Barebones mode
      # is useful for testing little jaba snippets where adding titles would be cumbersome.
      #
      if @title.nil? && !services.test_mode? && !services.barebones?
        JABA.error("requires a title")
      end

    rescue => e
      JABA.error("#{describe} invalid: #{e.message}", errobj: self)
    end

  end

end
