# frozen_string_literal: true

##
#
module JABA

  using JABACoreExt

  ##
  #
  class JabaDefinition

    attr_reader :id
    attr_reader :block
    attr_reader :source_location
    attr_reader :source_file
    attr_reader :source_line
    attr_reader :open_defs
    
    ##
    #
    def initialize(id, block, source_location)
      @id = id
      @block = block
      @source_location = source_location
      @source_file = @source_location.path
      @source_line = @source_location.lineno
      @open_defs = []
    end

    ##
    #
    def add_open_def(d)
      @open_defs << d
    end

    ##
    # Returns file and line number but using file basename instead of full path.
    #
    def src_loc_basename
      "#{@source_file.basename}:#{@source_line}"
    end

    ##
    # Returns file and line number as a path relative to root of jaba install. Used in reference manual generation.#
    #
    def src_loc_rel_jaba_root
      "#{@source_file.relative_path_from(JABA.jaba_root_dir)}:#{@source_line}"
    end
    
  end

  ##
  #
  class JabaInstanceDefinition < JabaDefinition
    
    include HookMethods

    attr_reader :jaba_type_id
    attr_reader :source_dir

    ##
    #
    def initialize(id, jaba_type_id, block, source_location)
      super(id, block, source_location)
      
      @jaba_type_id = jaba_type_id
      @source_dir = @source_file.dirname

      define_hook(:generate)
    end

  end

end
