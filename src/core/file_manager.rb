module JABA

  class StringWriter
    def initialize(...)
      @str = String.new(...)
    end
    def str = @str
    def to_s = @str
    def <<(str) = @str.concat(str, "\n")
    def write_raw(str) = @str.concat(str.to_s)
    def newline = @str.concat("\n")
    def chomp! = @str.chomp!
  end

  class JabaFile
    attr_reader :filename
    attr_reader :writer
    attr_reader :encoding

    def initialize(file_manager, filename, encoding, eol, capacity, track)
      @file_manager = file_manager
      @filename = filename
      @encoding = encoding
      @eol = eol
      @track = track
      @writer = work_area(capacity: capacity)
    end

    def work_area(capacity: nil)
      StringWriter.new(encoding: @encoding, capacity: capacity)
    end

    def str = @writer.str
    def track? = @track
    
    def write(**options)
      if (@eol == :windows) || ((@eol == :native) && OS.windows?)
        @writer.str.gsub!("\n", "\r\n")
      end
      @file_manager.write(self, **options)
    end
  end

  class FileManager
    attr_reader :services
    attr_reader :added
    attr_reader :modified
    attr_reader :unchanged
    attr_reader :generated

    ValidEols = [:unix, :windows, :native].freeze

    def initialize(services)
      @services = services
      @generated = []
      @generated_lookup = {}
      @added = []
      @modified = []
      @unchanged = []
      @untracked = []
    end

    def new_file(filename, eol: :unix, encoding: nil, capacity: nil, track: true)
      if !filename.absolute_path?
        JABA.error("'#{filename}' must be an absolute path")
      end
      if !ValidEols.include?(eol)
        JABA.error("'#{eol.inspect}' is an invalid eol style. Valid values: #{ValidEols.inspect}")
      end
      JabaFile.new(self, filename.cleanpath, encoding, eol, capacity, track)
    end

    def write(file)
      fn = file.filename

      if file.str.empty?
        services.jaba_warn("'#{fn}' is empty")
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

      if services.input.dry_run?
        services.log "Not writing #{fn} [dry run]"
      else
        if status
          services.log "Writing #{fn} [#{status}]"
        else
          services.log "Writing #{fn}"
        end

        dir = fn.parent_path
        if !exist?(dir)
          FileUtils.makedirs(dir)
        end

        if status != :UNCHANGED
          IO.binwrite(fn, file.str)
        end
      end
      status
    end

    def include_untracked = @generated.concat(@untracked)

    def read(filename, encoding: nil, fail_if_not_found: false, freeze: true)
      if !filename.absolute_path?
        JABA.error("'#{filename}' must be an absolute path")
      end

      fn = filename.cleanpath
      str = file_read_cache[fn]
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
          file_read_cache[fn] = str
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
      files = glob_cache[key]
      if files.nil?
        files = Dir.glob(spec, flags)
        files.reject!{|f| directory?(f)}
        files.freeze # Don't want cache entries being inadvertently modified
        glob_cache[key] = files
      end
      files
    end

    # Called from JDL API.
    #
    def jdl_glob(spec, &block)
      jaba_file_dir = $last_call_location.absolute_path.parent_path
      if !spec.absolute_path?
        spec = "#{jaba_file_dir}/#{spec}"
      end
      files = glob_files(spec)
      files = files.map{|f| f.relative_path_from(jaba_file_dir)}
      files.each(&block)
    end

    def exist?(fn)
      if !fn.absolute_path?
        JABA.error("'#{fn}' must be an absolute path")
      end
      exist = file_exist_cache[fn]
      if exist.nil?
        exist = File.exist?(fn)
        file_exist_cache[fn] = exist
      end
      exist
    end

    def directory?(fn)
      is_dir = is_directory_cache[fn]
      if is_dir.nil?
        is_dir = File.directory?(fn)
        is_directory_cache[fn] = is_dir
      end
      is_dir
    end

    # If running tests use the same file cache across all runs to speed them up as nothing odd happens to files
    # between tests. In production mode do caching per-jaba invocation (of which normally there would be only one),
    # but this allows flexibility to do more than one run with potentially anything changing between runs.
    
    def file_exist_cache
      if @services.test_mode?
        @@file_exist_cache ||= {}
      else
        @file_exist_cache ||= {}
      end
    end

    def is_directory_cache
      if @services.test_mode?
        @@is_directory_cache ||= {}
      else
        @is_directory_cache ||= {}
      end
    end

    def glob_cache
      if @services.test_mode?
        @@glob_cache ||= {}
      else
        @glob_cache ||= {}
      end
    end

    def file_read_cache
      if @services.test_mode?
        @@file_read_cache ||= {}
      else
        @file_read_cache ||= {}
      end
    end
  end
end
