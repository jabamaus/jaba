# frozen_string_literal: true

##
#
module JABA

  using JABACoreExt

  ##
  #
  class StringWriter
    
    ##
    #
    def initialize(...)
      @str = String.new(...)
    end

    ##
    #
    def str
      @str
    end

    ##
    #
    def to_s
      @str
    end

    ##
    #
    def <<(str)
      @str.concat(str, "\n")
    end
    
    ##
    #
    def write_raw(str)
      @str.concat(str.to_s)
    end
  
    ##
    #
    def newline
      @str.concat("\n")
    end
    
    ##
    #
    def chomp!
      @str.chomp!
    end

  end

  ##
  #
  class JabaFile

    attr_reader :filename
    attr_reader :writer
    attr_reader :encoding

    ##
    #
    def initialize(file_manager, filename, encoding, eol, capacity, track)
      @file_manager = file_manager
      @filename = filename
      @encoding = encoding
      @eol = eol
      @track = track
      @writer = work_area(capacity: capacity)
    end

    ##
    #
    def work_area(capacity: nil)
      StringWriter.new(encoding: @encoding, capacity: capacity)
    end

    ##
    #
    def str
      @writer.str
    end

    ##
    #
    def track?
      @track
    end
    
    ##
    #
    def write(**options)
      if (@eol == :windows) || ((@eol == :native) && OS.windows?)
        @writer.str.gsub!("\n", "\r\n")
      end
      @file_manager.write_file(self, **options)
    end

  end

  ##
  #
  class FileManager
    
    attr_reader :added
    attr_reader :modified
    attr_reader :generated

    ValidEols = [:unix, :windows, :native].freeze

    ##
    #
    def initialize(services)
      @services = services
      @generated = []
      @generated_tracker = {}
      @added = []
      @modified = []
    end

    ##
    #
    def new_file(filename, eol: :unix, encoding: nil, capacity: nil, track: true)
      if !ValidEols.include?(eol)
        raise "'#{eol.inspect}' is an invalid eol style. Valid values: #{ValidEols.inspect}"
      end
      JabaFile.new(self, filename.to_absolute(clean: true), encoding, eol, capacity, track)
    end

    ##
    #
    def write_file(file)
      fn = file.filename

      if file.str.empty?
        @services.jaba_warning("'#{fn}' is empty")
      end

      status = nil

      if file.track?
        existing = read_file(fn, encoding: file.encoding)
        if existing.nil?
          status = :ADDED
          @added << fn
        elsif existing != file.str
          status = :MODIFIED
          @modified << fn
        else
          status = :UNCHANGED
        end

        if @generated_tracker.key?(fn)
          @services.jaba_error("Duplicate filename '#{fn}' detected")
        end
        @generated << fn
        @generated_tracker[fn] = nil
      end

      if @services.input.dry_run?
        @services.log "Not writing #{fn} [dry run]"
      else
        if status
          @services.log "Writing #{fn} [#{status}]"
        else
          @services.log "Writing #{fn}"
        end

        dir = fn.dirname
        if !exist?(dir)
          FileUtils.makedirs(dir)
        end

        IO.binwrite(fn, file.str)
      end
    end

    ##
    #
    def read_file(filename, encoding: nil, fail_if_not_found: false)
      fn = filename.to_absolute(clean: true)
      str = file_read_cache[fn]
      if str.nil?
        if !exist?(fn)
          if fail_if_not_found
            jaba_error("'#{fn}' does not exist - cannot read")
          else
            return nil
          end
        else
          @services.log "Reading #{fn}"
          str = IO.binread(fn)
          str.force_encoding(encoding) if encoding
          str.freeze # Don't want cache entries being inadvertently modified
          file_read_cache[fn] = str
        end
      end
      str
    end

    ##
    #
    def glob(spec, flags=0)
      files = glob_cache[spec]
      if files.nil?
        files = Dir.glob(spec, flags)
        files.freeze # Don't want cache entries being inadvertently modified
        glob_cache[spec] = files
      end
      files
    end

    ##
    #
    def exist?(fn)
      exist = file_exist_cache[fn]
      if exist.nil?
        exist = File.exist?(fn)
        file_exist_cache[fn] = exist
      end
      exist
    end

    # If running tests use the same file cache across all runs to speed them up as nothing odd happens to files
    # between tests. In production mode do caching per-jaba invocation (of which normally there would be only one),
    # but this allows flexibility to do more than one run with potentially anything changing between runs.
    
    ##
    #
    def file_exist_cache
      if JABA.running_tests?
        @@file_exist_cache ||= {}
      else
        @file_exist_cache ||= {}
      end
    end

    ##
    #
    def glob_cache
      if JABA.running_tests?
        @@glob_cache ||= {}
      else
        @glob_cache ||= {}
      end
    end

    ##
    #
    def file_read_cache
      if JABA.running_tests?
        @@file_read_cache ||= {}
      else
        @file_read_cache ||= {}
      end
    end

  end

end
