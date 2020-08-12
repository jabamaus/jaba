# frozen_string_literal: true

##
#
module JABA

  using JABACoreExt

  ##
  #
  module PropertyMethods

    @@id_to_var = {}

    ##
    #
    def initialize(...)
      super
      @properties = {}
    end

    ##
    #
    def self.get_var(id)
      v = @@id_to_var[id]
      if !v
        v = "@#{id}"
        @@id_to_var[id] = v
      end
      v
    end

    ##
    #
    def define_property(p_id, val = nil)
      if @properties.key?(p_id)
        services.jaba_error("'#{p_id}' property multiply defined")
      end
      @properties[p_id] = nil
      var = PropertyMethods.get_var(p_id)
      instance_variable_set(var, val)
      define_singleton_method "get_#{p_id}" do
        instance_variable_get(var)
      end
    end

    ##
    #
    def define_array_property(p_id, val = [])
      define_property(p_id, val)
    end

    ##
    #
    def set_property(p_id, val = nil, &block)
      if !@properties.key?(p_id)
        services.jaba_error("Failed to set undefined '#{p_id}' property")
      end

      if block_given?
        if !val.nil?
          services.jaba_error('Must provide a default value or a block but not both')
        end
        val = block
        if pre_property_set(p_id, val) != :ignore
          instance_variable_set(PropertyMethods.get_var(p_id), val)
          post_property_set(p_id, val)
        end
      else
        current_val = instance_variable_get(PropertyMethods.get_var(p_id))
        if current_val.array?
          val = if val.array?
                  val.flatten # don't flatten! as might be frozen
                else
                  Array(val)
                end
          val.each do |elem|
            if pre_property_set(p_id, elem) != :ignore
              current_val << elem
              post_property_set(p_id, elem)
            end
          end
        else
          # Fail if setting a single value property as an array, unless its the first time. This is to allow
          # a property to become either single value or array, depending on how it is first initialised.
          #
          if !current_val.nil? && val.array?
            services.jaba_error("'#{p_id}' property cannot accept an array")
          end
          if pre_property_set(p_id, val) != :ignore
            instance_variable_set(PropertyMethods.get_var(p_id), val)
            post_property_set(p_id, val)
          end
        end
      end
    end
    
    ##
    # Override in subclass to validate value. If property is an array will be called for each element.
    # Return :ignore to cancel property set
    #
    def pre_property_set(id, incoming_val)
    end

    ##
    # Override in subclass to validate value. If property is an array will be called for each element.
    #
    def post_property_set(id, incoming_val)
    end

    ##
    #
    def get_property(p_id)
      if !@properties.key?(p_id)
        services.jaba_error("Failed to get undefined '#{p_id}' property")
      end
      instance_variable_get(PropertyMethods.get_var(p_id))
    end
    
    ##
    #
    def handle_property(p_id, val, &block)
      if val.nil? && !block_given?
        get_property(p_id)
      else
        set_property(p_id, val, &block)
      end
    end
    
  end
  
end
