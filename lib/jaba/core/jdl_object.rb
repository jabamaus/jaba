# frozen_string_literal: true

##
#
module JABA

  using JABACoreExt
  
  ##
  #
  class JDL_Object
    
    include HookMethods
    
    attr_reader :definition
    attr_reader :api
    attr_reader :defn_id # As specified by user in definition files.

    ##
    #
    def initialize(definition, api_object)
      super()
      @definition = definition
      @defn_id = definition.id
      @api = api_object
    end

    ##
    #
    def services
      @definition.services
    end

    ##
    #
    def to_s
      @defn_id.to_s
    end

    ##
    #
    def jaba_warning(...)
      services.jaba_warning(...)
    end

    ##
    #
    def jaba_error(...)
      services.jaba_error(...)
    end
    
    ##
    #
    def eval_jdl(*args, use_api: true, **keyval_args, &block)
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
      services.log "  Including shared definition [id=#{id}]"

      sd = services.get_shared_definition(id)
      
      n_expected = sd.block.arity
      n_actual = args ? Array(args).size : 0
      
      if n_actual != n_expected
        jaba_error("Shared definition '#{id}' expects #{n_expected} arguments but #{n_actual} were passed")
      end
      
      eval_jdl(args, &sd.block)
      sd.open_defs.each do |d|
        eval_jdl(args, &d.block)
      end
    end
    
  end
  
end
