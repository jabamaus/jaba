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
    attr_reader :defn_id # As specified by user in definition files.

    ##
    #
    def initialize(services, definition, api_object)
      super()
      @services = services
      @definition = definition
      @defn_id = definition.id
      @api = api_object
    end

    ##
    #
    def to_s
      @defn_id.to_s
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
    def eval_api_block(*args, use_api: true, **keyval_args, &block)
      receiver = use_api ? @api : self
      if args.empty? && keyval_args.empty?
        receiver.instance_eval(&block)
      else
        receiver.instance_exec(*args, **keyval_args, &block)
      end
    end
    
    ##
    #
    def include_shared(id, args)
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
