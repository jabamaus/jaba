# frozen_string_literal: true

##
#
module JABA

  using JABACoreExt
  
  ##
  #
  class JabaType < JabaObject

    attr_reader :title
    attr_reader :notes
    attr_reader :singleton
    attr_reader :plugin
    attr_reader :node_manager
    attr_reader :defaults_definition
    attr_reader :dependencies
    attr_reader :attribute_defs
    attr_reader :callable_attr_defs

    ##
    #
    def initialize(services, defn_id, src_loc, block, plugin, node_manager)
      super(services, defn_id, src_loc, JDL_Type.new(self))

      @attribute_defs = [] # The type's actual attribute defs
      @callable_attr_def_lookup = {} # All the attributes that can actually be called against this type. Includes referenced types.
      @callable_attr_defs = []
      @plugin = plugin
      @node_manager = node_manager
      @defaults_definition = services.get_defaults_definition(@defn_id)

      define_property :title
      define_array_property :notes
      define_property :singleton
      define_array_property :dependencies # TODO: validate explicitly specified deps

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
    # Used in error messages.
    #
    def describe
      "'#{@defn_id}' type"
    end

    ##
    #
    def define_attr(id, variant, type: nil, key_type: nil, &block)
      services.log "  Adding '#{id}' attribute [variant=#{variant}, type=#{type}]"
      
      if key_type && variant != :hash
        JABA.error("Only attr_hash supports :key_type argument")
      end
      
      validate_id(id)
      id = id.to_sym
      
      ad = JabaAttributeDefinition.new(@services, id, caller_locations(2, 1)[0], block, type, key_type, variant, self)
      @attribute_defs << ad

      register_attr_def(ad)
      ad  
    end

    ##
    #
    def get_attr_def(id)
      @callable_attr_def_lookup[id]
    end

    ##
    #
    def register_attr_def(attr_def)
      id = attr_def.defn_id
      existing = @callable_attr_def_lookup[id]
      if existing
        JABA.error("'#{id}' attribute multiply defined in '#{defn_id}'. Previous at #{existing.src_loc.describe}")
      end
      @callable_attr_def_lookup[id] = attr_def
      @callable_attr_defs << attr_def
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
      if @title.nil? && !JABA.running_tests? && !services.input.barebones
        JABA.error("requires a title")
      end

    rescue => e
      JABA.error("#{describe} invalid: #{e.message}", errobj: self)
    end

    ##
    #
    def post_create
      @dependencies.uniq!
      @dependencies.map!{|d| services.get_jaba_type(d)}

      # Regiser referenced attr defs
      #
      @attribute_defs.each do |attr_def|
        if attr_def.node_by_reference?
          rt_id = attr_def.node_type
          if rt_id != defn_id
            jt = attr_def.services.get_jaba_type(rt_id)
            jt.attribute_defs.each do |d|
              if d.has_flag?(:expose)
                register_attr_def(d)
              end
            end
          end
        end
      end

      @attribute_defs.sort_by!{|ad| ad.defn_id}
      @callable_attr_defs.sort_by!{|ad| ad.defn_id}
    end

    ##
    #
    def reference_manual_page(ext: '.html')
      "jaba_type_#{defn_id}#{ext}"
    end

  end

end
