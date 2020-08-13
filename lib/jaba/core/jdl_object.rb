# frozen_string_literal: true

##
#
module JABA

  using JABACoreExt
  
  ##
  #
  class JDL_Object
    
    include HookMethods
    
    attr_reader :services
    attr_reader :api
    attr_reader :defn_id # As specified by user in definition files.

    ##
    # Returns source location as a Thread::Backtrace::Location. See https://ruby-doc.org/core-2.7.1/Thread/Backtrace/Location.html.
    # Use this to pass to the callstack argument in jaba_error/jaba_warning. Do not embed in jaba_error/warning messages themselves
    # as it will appear as eg "C:/projects/GitHub/jaba/modules/cpp/cpp.jaba:49:in `block (2 levels) in execute_jdl'" - the "in `block`"
    # is not wanted in user level error messages. Instead use src_loc.describe.
    #
    attr_reader :src_loc

    ##
    #
    def initialize(services, defn_id, src_loc, api_object)
      super()
      @services = services
      @defn_id = defn_id
      @src_loc = src_loc
      @api = api_object
    end

    ##
    #
    def to_s
      @defn_id.to_s
    end

    ##
    #
    def source_dir
      @src_loc.path.dirname
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
      receiver.instance_exec(*args, **keyval_args, &block)
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
