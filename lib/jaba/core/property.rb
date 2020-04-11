# frozen_string_literal: true

##
#
module JABA

  using JABACoreExt

  module PropertyMethods

    ##
    #
    def set_property(var_name, val = nil, &block)
      if block_given?
        if !val.nil?
          @services.jaba_error('Must provide a default value or a block but not both')
        end
        instance_variable_set("@#{var_name}", block)
      else
        if !instance_variable_defined?("@#{var_name}")
          instance_variable_set("@#{var_name}", val)
        else
          var = instance_variable_get("@#{var_name}")
          if var.is_a?(Array)
            var.concat(Array(val))
          else
            instance_variable_set("@#{var_name}", val)
          end
        end
      end
    end
    
    ##
    #
    def get_property(var_name)
      instance_variable_get("@#{var_name}")
    end
    
    ##
    #
    def handle_property(id, val, &block)
      if !instance_variable_defined?("@#{id}")
        @services.jaba_error("'#{id}' property not defined")
      end
      if val.nil?
        get_property(id)
      else
        set_property(id, val, &block)
      end
    end
    
  end

end
