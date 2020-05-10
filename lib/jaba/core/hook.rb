# frozen_string_literal: true

##
#
module JABA

  using JABACoreExt

  ##
  #
  module HookMethods
    
    ##
    #
    def define_hook(id, &block)
      var = "@#{id}_hook" # TODO: improve
      if instance_variable_defined?(var)
        jaba_error("'#{id}' hook multiply defined")
      end
      if block_given?
        instance_variable_set(var, block)
      else
        instance_variable_set(var, nil)
      end
    end

    ##
    #
    def set_hook(id, &block)
      var = "@#{id}_hook" # TODO: improve
      if !instance_variable_defined?(var)
        jaba_error("'#{id}' hook not defined")
      end
      instance_variable_set(var, block)
    end

    ##
    #
    def call_hook(id, args = nil, receiver: self, fail_if_not_set: false)
      var = "@#{id}_hook" # TODO: improve
      if !instance_variable_defined?(var)
        jaba_error("'#{id}' hook not defined")
      end
      block = instance_variable_get(var)
      if block.nil?
        if fail_if_not_set
          jaba_error("'#{id}' not set - cannot call'")
        end
      else
        receiver.eval_api_block(args, &block)
      end
    end

  end

end
