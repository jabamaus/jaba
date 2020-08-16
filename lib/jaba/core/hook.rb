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
    def initialize(...)
      super
      @hooks = {}
    end

    ##
    #
    def define_hook(id, &block)
      if @hooks.key?(id)
        raise "'#{id}' hook multiply defined"
      end
      hook = block_given? ? block : :not_set
      @hooks[id] = hook
    end

    ##
    #
    def hook_defined?(id)
      @hooks.key?(id)
    end

    ##
    #
    def set_hook(id, &block)
      if !hook_defined?(id)
        raise "'#{id}' hook not defined"
      end
      on_hook_defined(id)
      @hooks[id] = block
    end

    ##
    #
    def call_hook(id, *args, receiver: self, fail_if_not_set: false, **keyval_args)
      block = @hooks[id]
      if !block
        raise "'#{id}' hook not defined"
      elsif block == :not_set
        if fail_if_not_set
          raise "'#{id}' not set - cannot call'"
        end
        return nil
      else
        receiver.eval_jdl(*args, **keyval_args, &block)
      end
    end

    ##
    #
    def on_hook_defined(id)
    end
    
  end

end
