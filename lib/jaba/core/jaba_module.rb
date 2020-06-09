# frozen_string_literal: true

module JABA

  using JABACoreExt

  ##
  #
  class JabaModule

    ##
    #
    def initialize(services)
      @services = services
      @code_files = []
      @jdl_files = []
    end

    ##
    #
    def load
      @code_files.each do |cf|
        require cf
      end
      @jdl_file_contents = @jdl_files.map{|f| @services.file_manager.read_file(f)}
    end

    ##
    #
    def execute
      @jdl_file_contents.each_with_index do |str, i|
        file = @jdl_files[i]
        @services.execute_jdl(str, file)
      end
    end

  end

  ##
  #
  class PluginModule < JabaModule
  
    ##
    #
    def initialize(services, root_dir)
      super(services)
      @root_dir = root_dir
    end

    ##
    #
    def gather_files
      files = @services.file_manager.glob("#{@root_dir}/**/*.rb")
      @jdl_files, @code_files = files.partition{|f| f =~ /jdl\.rb/}
    end

  end

  ##
  #
  class UserModule < JabaModule

    ##
    #
    def initialize(services, load_paths)
      super(services)
      @load_paths = load_paths
    end

    ##
    #
    def gather_files
      Array(@load_paths).each do |p|
        p = p.to_absolute(clean: true)

        if !File.exist?(p)
          jaba_error("#{p} does not exist")
        end

        if File.directory?(p)
          files = @services.file_manager.glob("#{p}/**/*.jdl.rb")
          if files.empty?
            jaba_warning("No definition files found in #{p}")
          else
            @jdl_files.concat(files)
          end
        else
          @jdl_files << p
        end
      end
    end

  end

end
