# frozen_string_literal: true

##
#
module JABA

  using JABACoreExt
  
  ##
  #
  class JabaType < JabaObject

    include PropertyMethods

    attr_reader :title
    attr_reader :notes
    attr_reader :singleton
    attr_reader :plugin
    attr_reader :node_manager
    attr_reader :defaults_definition
    attr_reader :dependencies
    attr_reader :attribute_defs

    ##
    #
    def initialize(services, defn_id, src_loc, block, plugin, node_manager)
      super(services, defn_id, src_loc, JDL_Type.new(self))

      @attribute_defs = []
      @all_attr_defs = {}
      @plugin = plugin
      @node_manager = node_manager
      @defaults_definition = services.get_defaults_definition(@defn_id)

      define_property :title
      define_array_property :notes
      define_property :singleton
      define_array_property :dependencies # TODO: validate explicitly specified deps
      define_array_property :child_types

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

      register_attr_def(id, ad)
      ad  
    end

    ##
    #
    def get_attr_def(id)
      @all_attr_defs[id]
    end

    ##
    #
    def register_attr_def(id, attr_def)
      existing = @all_attr_defs[id]
      if existing
        JABA.error("'#{id}' attribute multiply defined in '#{defn_id}'. Previous at #{existing.src_loc.describe}")
      end
      @all_attr_defs[id] = attr_def
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
    def get_child_type(type_id)
      ct = @child_types.find{|jt| jt.defn_id == type_id}
      if !ct
        JABA.error("#{describe} does not have '#{type_id}' child type")
      end
      ct
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
      @child_types.map!{|id| services.get_jaba_type(id)}
      @attribute_defs.sort_by! {|ad| ad.defn_id}

      to_register = []

      @child_types.each do |ct|
        to_register.concat(ct.attribute_defs)
      end

      # Register referenced attributes
      #
      @all_attr_defs.each do |id, attr_def|
        if attr_def.node_by_reference?
          rt_id = attr_def.node_type
          if rt_id != defn_id
            jt = attr_def.services.get_jaba_type(rt_id)
            jt.attribute_defs.each do |d|
              if d.has_flag?(:expose)
                to_register << d
              end
            end
          end
        end
      end

 
      to_register.each{|d| register_attr_def(d.defn_id, d)}

      # Convert dependencies specified as ids to jaba type objects
      #
      @dependencies.uniq!
      @dependencies.map! {|dep| services.get_jaba_type(dep)}
    end

    ##
    #
    def reference_manual_page(ext: '.html')
      "jaba_type_#{defn_id}#{ext}"
    end

  end

end
