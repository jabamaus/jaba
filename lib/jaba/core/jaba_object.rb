# frozen_string_literal: true

##
#
module JABA

  using JABACoreExt
  
  ##
  #
  class JabaObject
    
    attr_reader :services
    
    ##
    #
    def initialize(services)
      @services = services
    end
    
    ##
    #
    def eval_obj(context)
      self
    end
    
    ##
    #
    def jaba_error(msg, **options)
      @services.jaba_error(msg, **options)
    end
    
    ##
    #
    def eval_definition(args = nil, context: :definition, &block)
      return if !block_given?
      if !args.nil?
        eval_obj(context).instance_exec(args, &block)
      else
        eval_obj(context).instance_eval(&block)
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
        
        eval_definition(args, &df.block)
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
