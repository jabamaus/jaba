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
    def get_var(id)
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
      var = get_var(p_id)
      if instance_variable_defined?(var)
        @services.jaba_error("'#{p_id}' property multiply defined")
      end

      instance_variable_set(var, val)
    end

    ##
    #
    def define_array_property(p_id, val = [])
      var = get_var(p_id)
      if instance_variable_defined?(var)
        @services.jaba_error("'#{p_id}' property multiply defined")
      end

      instance_variable_set(var, val)
    end

    ##
    #
    def set_property(p_id, val = nil, &block)
      var = get_var(p_id)
      if !instance_variable_defined?(var)
        @services.jaba_error("'#{p_id}' property not defined")
      end

      if block_given?
        if !val.nil?
          @services.jaba_error('Must provide a default value or a block but not both')
        end
        instance_variable_set(var, block)
      else
        current_val = instance_variable_get(var)
        if current_val.is_a?(Array)
          if val.is_a?(Array)
            val.flatten!
            current_val.concat(val)
          else
            current_val << val
          end
        else
          # Fail if setting a single value property as an array, unless its the first time. This is to allow
          # a property to become either single value or array, depending on how it is first initialised.
          #
          if !current_val.nil? && val.is_a?(Array)
            @services.jaba_error("'#{p_id}' property cannot accept an array")
          end
          instance_variable_set(var, val)
        end
        on_property_set(p_id, val)
      end
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
      var = get_var(p_id)
      if !instance_variable_defined?(var)
        @services.jaba_error("'#{p_id}' property not defined")
      end
      instance_variable_get(var)
    end
    
    ##
    #
    def handle_property(p_id, val, &block)
      if val.nil?
        get_property(p_id)
      else
        set_property(p_id, val, &block)
      end
    end
    
  end
  
end
