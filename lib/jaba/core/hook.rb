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
        jaba_error("'#{id}' hook multiply defined")
      end
      hook = block_given? ? block : :not_set
      @hooks[id] = hook
    end

    ##
    #
    def set_hook(id, &block)
      if !@hooks.key?(id)
        jaba_error("'#{id}' hook not defined")
      end
      @hooks[id] = block
    end

    ##
    #
    def call_hook(id, *args, receiver: self, fail_if_not_set: false, **keyval_args)
      block = @hooks[id]
      if !block
        jaba_error("'#{id}' hook not defined")
      elsif block == :not_set
        if fail_if_not_set
          jaba_error("'#{id}' not set - cannot call'")
        end
        return nil
      else
        receiver.eval_api_block(*args, **keyval_args, &block)
      end
    end

  end

end
