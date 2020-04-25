# frozen_string_literal: true

##
#
module JABA

  using JABACoreExt
  
  ##
  #
  class JabaObject
    
    attr_reader :services
    attr_reader :definition_id # As specified by user in definition files.
    attr_reader :api
    attr_reader :api_call_line

    ##
    #
    def initialize(services, def_block, api_object)
      @services = services
      @definition_block = def_block
      @definition_id = def_block.definition_id
      @api_call_line = def_block.api_call_line
      @api = api_object
    end

    ##
    #
    def to_s
      @definition_block.definition_id.to_s
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
        @services.log "  Including shared definition [id=#{id}]"

        db = @services.get_shared_definition_block(id)
        
        n_expected = db.block.arity
        n_actual = args ? Array(args).size : 0
        
        if n_actual != n_expected
          jaba_error("shared definition '#{id}' expects #{n_expected} arguments but #{n_actual} were passed")
        end
        
        eval_api_block(args, &db.block)
      end
    end
    
    ##
    #
    def define_hook(id, &block)
      var = "@#{id}_hook"
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
      var = "@#{id}_hook"
      if !instance_variable_defined?(var)
        jaba_error("'#{id}' hook not defined")
      end
      instance_variable_set(var, block)
    end

    ##
    #
    def call_hook(id, args = nil, receiver: self, fail_if_not_set: false)
      var = "@#{id}_hook"
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
