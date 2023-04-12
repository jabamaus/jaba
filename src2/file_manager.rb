module JABA
  class StringWriter
    def initialize(encoding: nil)
      @str = if mruby?
          JABA.error("Only UTF-8 encoding supported") if (encoding && encoding != "UTF-8")
          String.new # mruby is UTF-8 as standard via MRB_UTF8_STRING define
        else
          String.new(encoding: encoding)
        end
    end

    def str = @str
    def to_s = @str
    def <<(str) = @str.concat(str, "\n")
    def write_raw(str) = @str.concat(str.to_s)
    def newline = @str.concat("\n")
    def chomp! = @str.chomp!
  end

  class JabaFile
    def initialize(file_manager, filename, encoding, eol, track)
      @file_manager = file_manager
      @filename = filename
      @encoding = encoding
      @eol = eol
      @track = track
      @writer = work_area
    end

    def work_area = StringWriter.new(encoding: @encoding)
    def filename = @filename
    def writer = @writer
    def encoding = @encoding
    def str = @writer.str
    def track? = @track

    def write(...)
      if (@eol == :windows) || ((@eol == :native) && OS.windows?)
        @writer.str.gsub!("\n", "\r\n")
      end
      @file_manager.write(self, ...)
    end
  end

  class FileManager
    def initialize
      @generated = []
      @generated_lookup = {}
      @added = []
      @modified = []
      @unchanged = []
      @untracked = []
      @file_exist_cache = {}
      @glob_cache = {}
      @file_read_cache = {}
      @is_directory_cache = {}
    end

    def added = @added
    def modified = @modified
    def unchanged = @unchanged
    def generated = @generated

    ValidEols = [:unix, :windows, :native].freeze

    def new_file(filename, eol: :unix, encoding: nil, track: true)
      if !filename.absolute_path?
        JABA.error("'#{filename}' must be an absolute path")
      end
      if !ValidEols.include?(eol)
        JABA.error("'#{eol.inspect}' is an invalid eol style. Valid values: #{ValidEols.inspect}")
      end
      JabaFile.new(self, filename.cleanpath, encoding, eol, track)
    end

    def write(file)
      fn = file.filename

      if file.str.empty?
        JABA.warn("'#{fn}' is empty")
      end

      if @generated_lookup.key?(fn)
        JABA.error("Duplicate filename '#{fn}' detected")
      end

      existing = read(fn, encoding: file.encoding)

      status = if existing.nil?
          @added << fn
          :ADDED
        elsif existing != file.str
          @modified << fn
          :MODIFIED
        else
          @unchanged << fn
          :UNCHANGED
        end

      if file.track?
        @generated << fn
      else
        @untracked << fn
      end
      @generated_lookup[fn] = nil

      if status
        JABA.log "Writing #{fn} [#{status}]"
      else
        JABA.log "Writing #{fn}"
      end

      dir = fn.parent_path
      if !exist?(dir)
        FileUtils.makedirs(dir)
      end

      if status != :UNCHANGED
        IO.binwrite(fn, file.str)
      end
      status
    end

    def include_untracked = @generated.concat(@untracked)

    def read(filename, encoding: nil, fail_if_not_found: false, freeze: true)
      if !filename.absolute_path?
        JABA.error("'#{filename}' must be an absolute path")
      end

      fn = filename.cleanpath
      str = @file_read_cache[fn]
      if str.nil?
        if !exist?(fn)
          if fail_if_not_found
            JABA.error("'#{fn}' does not exist - cannot read")
          else
            return nil
          end
        else
          str = IO.binread(fn)
          str.force_encoding(encoding) if encoding
          str.freeze if freeze # Don't want cache entries being inadvertently modified
          @file_read_cache[fn] = str
        end
      end
      str
    end

    # Only returns files, not directories.
    #
    def glob_files(spec, flags: 0)
      if !spec.absolute_path?
        JABA.error("'#{spec}' must be an absolute path")
      end
      key = "#{spec}#{flags}"
      files = @glob_cache[key]
      if files.nil?
        files = Dir.glob(spec, flags)
        files.reject! { |f| directory?(f) }
        files.freeze # Don't want cache entries being inadvertently modified
        @glob_cache[key] = files
      end
      files
    end

    def exist?(fn)
      if !fn.absolute_path?
        JABA.error("'#{fn}' must be an absolute path")
      end
      exist = @file_exist_cache[fn]
      if exist.nil?
        exist = File.exist?(fn)
        @file_exist_cache[fn] = exist
      end
      exist
    end

    def directory?(fn)
      is_dir = @is_directory_cache[fn]
      if is_dir.nil?
        is_dir = File.directory?(fn)
        @is_directory_cache[fn] = is_dir
      end
      is_dir
    end
  end
end
