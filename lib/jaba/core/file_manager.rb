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
    def initialize(file_manager, filename, encoding, eol, capacity)
      @file_manager = file_manager
      @filename = filename
      @encoding = encoding
      @eol = eol
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
    def save(**options)
      if (@eol == :windows) || ((@eol == :native) && OS.windows?)
        @writer.str.gsub!("\n", "\r\n")
      end
      @file_manager.save(self, **options)
    end

  end

  ##
  #
  class FileManager
    
    @@file_read_cache = {}

    attr_reader :added
    attr_reader :modified
    attr_reader :generated

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
    def new_file(filename, eol: nil, encoding: nil, capacity: nil)
      filename = File.expand_path(filename.cleanpath)
      JabaFile.new(self, filename, encoding, eol, capacity)
    end

    ##
    #
    def save(file, track: true)
      fn = file.filename

      if track
        existing = read_file(fn, encoding: file.encoding)
        if existing.nil?
          @added << fn
        elsif existing != file.str
          @modified << fn
        end

        if @generated_tracker.key?(fn)
          @services.jaba_error("Duplicate filename '#{fn}' detected")
        end
        @generated << fn
        @generated_tracker[fn] = nil
      end

      if @services.input.dry_run?
        @services.log "Not saving #{fn} [dry run]"
      else
        @services.log "Saving #{fn}"

        # TODO: optimise
        dir = File.dirname(fn)
        if !File.exist?(dir)
          FileUtils.makedirs(dir)
        end

        IO.binwrite(fn, file.str)
      end
    end

    ##
    #
    def read_file(filename, encoding: nil, fail_if_not_found: false)
      fn = File.expand_path(filename.cleanpath)
      str = @@file_read_cache[fn]
      if str.nil?
        if !File.exist?(fn)
          if fail_if_not_found
            jaba_error("'#{fn}' does not exist - cannot read")
          else
            return nil
          end
        else
          str = IO.binread(fn)
          str.force_encoding(encoding) if encoding
          @@file_read_cache[fn] = str
        end
      end
      str
    end

  end

end