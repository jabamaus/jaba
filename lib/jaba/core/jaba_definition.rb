# frozen_string_literal: true

##
#
module JABA

  using JABACoreExt

  ##
  #
  class JabaDefinition

    attr_reader :services
    attr_reader :id
    attr_reader :block
    attr_reader :source_file # Absolute path to the file definition defined in
    attr_reader :source_line # Line number of start of definition
    attr_reader :open_defs
    
    ##
    #
    def initialize(services, id, block, source_location)
      @services = services
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
    # Returns source location as a Thread::Backtrace::Location. See https://ruby-doc.org/core-2.7.1/Thread/Backtrace/Location.html.
    # Use this to pass to the callstack argument in jaba_error/jaba_warning. Do not embed in jaba_error/warning messages themselves
    # as it will appear as eg "C:/projects/GitHub/jaba/modules/cpp/cpp.jdl.rb:49:in `block (2 levels) in execute_jdl'" - the "in `block`"
    # is not wanted in user level error messages. Instead use the src_loc_describe method.
    #
    def src_loc_raw
      @source_location
    end

    ##
    # Formats source location for use in user level messages.
    #
    def src_loc_describe(style: :basename)
      case style
      when :absolute
        "#{@source_file}:#{@source_line}"
      when :basename
        "#{@source_file.basename}:#{@source_line}"
      when :rel_jaba_root
        "#{@source_file.relative_path_from(JABA.jaba_root_dir)}:#{@source_line}"
      else
        services.jaba_error("Unsupported style '#{style}'")
      end
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
    def initialize(services, id, jaba_type_id, block, source_location)
      super(services, id, block, source_location)
      
      @jaba_type_id = jaba_type_id
      @source_dir = @source_file.dirname

      define_hook(:generate)
    end

  end

end
