module JABA

  ##
  #
  class LoadManager
    
    @@module_files_loaded = false
    @@module_jaba_files = []

    attr_reader :jdl_files

    ##
    #
    def initialize(services, file_manager)
      @services = services
      @file_manager = file_manager
      @jdl_files = []
      @jdl_includes = []
      @jdl_file_lookup = {}
    end

    ##
    #
    def load_modules
      # Only loaded once in a given process even if jaba invoked multiple times. Helps with effiency of tests.
      #
      return if @@module_files_loaded
      @@module_files_loaded = true
      plugin_files = []

      Dir.glob("#{JABA.modules_dir}/**/*").each do |f|
        case f.extname
        when '.rb'
          plugin_files << f
        when '.jaba'
          @@module_jaba_files << f
        end
      end
      plugin_files.each do |f|
        load_plugin(f)
      end
    end

    ##
    #
    def load_jaba_files(input)
      if input.barebones? # optimisation for unit testing
        process_jaba_file("#{JABA.modules_dir}/core/globals.jaba")
        process_jaba_file("#{JABA.modules_dir}/core/hosts.jaba")
      else
        @@module_jaba_files.each do |f|
          process_jaba_file(f)
        end
      end

      if input.src_root
        process_load_path(input.src_root, fail_if_empty: true)
      end

      # Definitions can also be provided in a block form
      #
      Array(input.definitions).each do |block|
        block_file = block.source_location[0].cleanpath
        @jdl_files << block_file
        @services.execute_jdl(&block)
      end

      # Process include directives, accounting for included files including other files.
      #
      while !@jdl_includes.empty?
        last = @jdl_includes.pop
        process_load_path(last)
      end
    end

    ##
    #
    def load_plugin(f)
      begin
        require f
      rescue ScriptError => e
        JABA.error("Failed to load #{f}: #{e.message}")
      end
    end

    ##
    #
    def load_path_valid?(path)
      !@file_manager.glob_files("#{path}/*.jaba").empty?
    end

    ##
    #
    def process_load_path(p, fail_if_empty: false)
      if !p.absolute_path?
        JABA.error("'#{p}' must be an absolute path")
      end

      if !File.exist?(p)
        JABA.error("'#{p}' does not exist", want_backtrace: false)
      end

      if @file_manager.directory?(p)
        files = @file_manager.glob_files("#{p}/*.jaba")
        if files.empty?
          msg = "No .jaba files found in '#{p}'"
          if fail_if_empty
            JABA.error(msg, want_backtrace: false)
          else
            jaba_warn(msg)
          end
        else
          files.each do |f|
            process_jaba_file(f)
          end
        end
      else
        process_jaba_file(p)
      end
    end

    ##
    #
    def process_jaba_file(f)
      if !f.absolute_path?
        JABA.error("'#{f}' must be an absolute path")
      end
      f = f.cleanpath # TODO: needed?

      if @jdl_file_lookup.has_key?(f)
        # Already loaded. Ignore.
        return
      end
      
      @jdl_file_lookup[f] = nil
      @jdl_files << f

      @services.execute_jdl(file: f)
    end

    ##
    #
    def process_include(path, base:)
      if block_given?
        # If block given, execute arbitrary code. Plugins can be defined inline in this way.
        yield
      end
      if path
        if base == :grab_bag
          if path.absolute_path?
            JABA.error("'#{path}' must not be absolute if basing it on jaba grab_bag directory")
          end
          path = "#{JABA.grab_bag_dir}/#{path}"
        elsif !path.absolute_path?
          src_loc = caller_locations(2, 1)[0]
          path = "#{src_loc.absolute_path.parent_path}/#{path}"
        end
        if path.extname == '.rb'
          @services.log "  Loading #{path} plugin"
          load_plugin(path)
        else
          if path.wildcard?
            @jdl_includes.concat(Dir.glob(path))
          else
            @jdl_includes << path
          end
        end
      end
    end

  end

end
