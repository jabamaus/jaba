module JABA
  # TODO: move back into context
  class LoadManager
    def initialize(context, file_manager)
      @context = context
      @file_manager = file_manager
      @jdl_files = []
      @jdl_includes = []
      @jdl_file_lookup = {}
    end

    def context = @context
    def jdl_files = @jdl_files

    def load_jaba_files
      if context.src_root
        process_load_path(context.src_root, fail_if_empty: true)
      end

      # Definitions can also be provided in a block form
      #
      Array(context.input.definitions).each do |block|
        block_file = block.source_location[0].cleanpath
        @jdl_files << block_file
        @context.execute_jdl(&block)
      end

      # Process include directives, accounting for included files including other files.
      #
      while !@jdl_includes.empty?
        inc = @jdl_includes.pop
        process_load_path(inc.path)
      end
    end

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
            @context.jaba_warn(msg)
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

      @context.execute_jdl(file: f)
    end

    IncludeInfo = Struct.new(:path, :args)

    def process_include(path)
      if path.nil?
        JABA.error("include requires a path")
      end
      if !path.absolute_path?
        path = "#{$last_call_location.absolute_path.parent_path}/#{path}"
      end
      if path.wildcard?
        @jdl_includes.concat(Dir.glob(path).map{|d| IncludeInfo.new(d, args)})
      else
        @jdl_includes << IncludeInfo.new(path, args)
      end
    end
  end
end
