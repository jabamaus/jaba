# frozen_string_literal: true

##
#
module JABA

  using JABACoreExt
  
  ##
  #
  class JabaObject
    
    attr_reader :services
    attr_reader :api
    
    ##
    #
    def initialize(services, api_object)
      @services = services
      @api = api_object
    end
    
    ##
    #
    def jaba_error(msg, **options)
      @services.jaba_error(msg, **options)
    end
    
    ##
    #
    def eval_api_block(args = nil, &block)
      return if !block_given?
      if !args.nil?
        @api.instance_exec(args, &block)
      else
        @api.instance_eval(&block)
      end
    end
    
    ##
    #
    def include_shared(ids, args)
      ids.each do |id|
        df = @services.get_definition(:shared, id, fail_if_not_found: false)
        if !df
          @services.jaba_error("Shared definition '#{id}' not found")
        end
        
        n_expected = df.block.arity
        n_actual = args ? Array(args).size : 0
        
        if n_actual != n_expected
          @services.jaba_error("shared definition '#{id}' expects #{n_expected} arguments but #{n_actual} were passed")
        end
        
        eval_api_block(args, &df.block)
      end
    end
    
    ##
    # TODO: test
    def define_hook(id, allow_multiple: false, &block)
      if allow_multiple
        instance_variable_get("@#{id}_hooks") << block
      else
        hook = "@#{id}_hook"
        if instance_variable_get(hook)
          @services.jaba_error("'#{id}' hook already set")
        end
        instance_variable_set(hook, block)
      end
    end
    
  end
  
end
