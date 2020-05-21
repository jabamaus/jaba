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
        @services.jaba_error("'#{p_id}' property multiply defined")
      end
      @properties[p_id] = nil
      instance_variable_set(PropertyMethods.get_var(p_id), val)
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
        @services.jaba_error("'#{p_id}' property not defined")
      end

      if block_given?
        if !val.nil?
          @services.jaba_error('Must provide a default value or a block but not both')
        end
        val = block
        instance_variable_set(PropertyMethods.get_var(p_id), val)
      else
        current_val = instance_variable_get(PropertyMethods.get_var(p_id))
        if current_val.is_a?(Array)
          if val.is_a?(Array)
            val = val.flatten # don't flatten! as might be frozen
          else
            val = Array(val)
          end
          current_val.concat(val)
        else
          # Fail if setting a single value property as an array, unless its the first time. This is to allow
          # a property to become either single value or array, depending on how it is first initialised.
          #
          if !current_val.nil? && val.is_a?(Array)
            @services.jaba_error("'#{p_id}' property cannot accept an array")
          end
          instance_variable_set(PropertyMethods.get_var(p_id), val)
        end
      end
      on_property_set(p_id, val)
    end
    
    ##
    # Override in subclass to validate value.
    #
    def on_property_set(id, incoming_val)
      # nothing
    end

    ##
    #
    def get_property(p_id)
      if !@properties.key?(p_id)
        @services.jaba_error("'#{p_id}' property not defined")
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
