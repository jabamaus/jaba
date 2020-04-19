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
      if args.nil?
        @api.instance_eval(&block)
      else
        @api.instance_exec(args, &block)
      end
    end
    
    ##
    #
    def include_shared(ids, args)
      ids.each do |id|
        info = @services.get_instance_info(:shared, id, fail_if_not_found: false)
        if !info
          jaba_error("Shared definition '#{id}' not found")
        end
        
        n_expected = info.block.arity
        n_actual = args ? Array(args).size : 0
        
        if n_actual != n_expected
          jaba_error("shared definition '#{id}' expects #{n_expected} arguments but #{n_actual} were passed")
        end
        
        eval_api_block(args, &info.block)
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
          jaba_error("'#{id}' hook already set")
        end
        instance_variable_set(hook, block)
      end
    end
    
  end
  
end
