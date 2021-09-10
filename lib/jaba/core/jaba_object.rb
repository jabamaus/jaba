module JABA

  ##
  #
  class JabaObject
    
    include PropertyMethods
    
    attr_reader :services
    attr_reader :api
    attr_reader :defn_id # As specified by user in definition files.

    ##
    # Returns source location as a Thread::Backtrace::Location.
    # Use this to pass to the callstack argument in JABA.error/jaba_warn. Do not embed in JABA.error/warning messages themselves
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
      @src_loc.path.parent_path
    end

    ##
    #
    def jaba_warn(...)
      services.jaba_warn(...)
    end

    ##
    #
    def eval_jdl(*args, use_api: true, receiver: nil, **keyval_args, &block)
      obj = receiver ? receiver : self
      obj = use_api ? obj.api : obj
      obj.instance_exec(*args, **keyval_args, &block)
    end

    ##
    #
    def call_block_property(p_id, *args, **keyval_args)
      b = get_property(p_id)
      if b
        eval_jdl(*args, **keyval_args, &b)
      end
    end
    
    ##
    #
    def include_shared(id, args)
      services.log "  Including shared definition [id=#{id}]"

      sd = services.get_definition(:shared, id)
      
      n_expected = sd.block.arity
      n_actual = args ? Array(args).size : 0
      
      if n_actual != n_expected
        JABA.error("Shared definition '#{id.inspect_unquoted}' expects #{n_expected} arguments but #{n_actual} were passed")
      end
      
      eval_jdl(*args, &sd.block)
      sd.open_defs&.each do |d|
        eval_jdl(*args, &d.block)
      end
    end
    
  end
  
end
