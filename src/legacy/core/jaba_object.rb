module JABA

  class JabaObject
    include PropertyMethods
    
    attr_reader :services
    attr_reader :api
    attr_reader :defn_id # As specified by user in definition files.

    # Returns source location as file:line
    # Use this to pass to the callstack argument in JABA.error/jaba_warn. Do not embed in JABA.error/warning messages themselves
    # as it will appear as eg "C:/projects/GitHub/jaba/modules/cpp/cpp.jaba:49:in `block (2 levels) in execute_jdl'" - the "in `block`"
    # is not wanted in user level error messages. Instead use src_loc.src_loc_describe.
    #
    attr_reader :src_loc

    def initialize(services, defn_id, src_loc, api_object)
      super()
      @services = services
      @defn_id = defn_id
      @src_loc = src_loc
      @api = api_object
    end

    def to_s = @defn_id.to_s
    def source_dir = @src_loc.src_loc_info[0].parent_path

    def jaba_warn(...) = services.jaba_warn(...)

    def eval_jdl(*args, use_api: true, receiver: nil, **keyval_args, &block)
      obj = receiver ? receiver : self
      obj = use_api ? obj.api : obj
      obj.instance_exec(*args, **keyval_args, &block)
    end

    def call_block_property(p_id, *args, **keyval_args)
      b = get_property(p_id)
      if b
        eval_jdl(*args, **keyval_args, &b)
      end
    end
    
    def include_shared(id, **keyval_args)
      services.log "  Including shared definition [id=#{id}]"

      sd = services.get_definition(:shared, id)

      eval_jdl(**keyval_args, &sd.block)
      sd.open_defs&.each do |d|
        eval_jdl(**keyval_args, &d.block)
      end
    end
  end
end
