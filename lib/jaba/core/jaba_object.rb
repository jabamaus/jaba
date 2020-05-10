# frozen_string_literal: true

##
#
module JABA

  using JABACoreExt
  
  ##
  #
  class JabaObject
    
    include HookMethods
    
    attr_reader :services
    attr_reader :definition
    attr_reader :api

    ##
    #
    def initialize(services, definition, api_object)
      @services = services
      @definition = definition
      @api = api_object
    end

    ##
    # As specified by user in definition files.
    #
    def definition_id
      @definition.id
    end

    ##
    #
    def to_s
      @definition.id.to_s
    end

    ##
    #
    def jaba_warning(msg, **options)
      @services.jaba_warning(msg, **options)
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

        db = @services.get_shared_definition(id)
        
        n_expected = db.block.arity
        n_actual = args ? Array(args).size : 0
        
        if n_actual != n_expected
          jaba_error("shared definition '#{id}' expects #{n_expected} arguments but #{n_actual} were passed")
        end
        
        eval_api_block(args, &db.block)
      end
    end
    
  end
  
end
