# frozen_string_literal: true

##
#
module JABA

  using JABACoreExt
  
  SourceFile = Struct.new(:absolute_path, :projroot_rel, :vpath, :file_type)

  ##
  # Base class for instances of projects, eg a Visual Studio project/Xcode project/makefile etc.
  #
  class Project
    
    attr_reader :attrs
    attr_reader :projroot
    attr_reader :projname
    
    ##
    #
    def initialize(services, generator, node, root)
      @services = services
      @generator = generator # required in order to look up other projects when resolving dependencies
      @node = node
      @root = root
      @attrs = node.attrs
      @projroot = @attrs.projroot
      @projname = @attrs.projname
    end
    
    ##
    # eg cpp|MyApp|vs2019|windows
    #
    def handle
      @node.handle
    end

    ##
    # Override this in subclass.
    #
    def generate
      # nothing
    end

    ##
    # Override this in subclass.
    #
    def build_jaba_output(p_root, out_dir)
      # nothing
    end

    ##
    # Override in subclass if project uses backslashes (eg Visual Studio)
    #
    def want_backslashes?
      false
    end

    ##
    # Override in subclass if necessary. Yields eg :ClCompile given '.cpp' when targeting Visual Studio C++.
    #
    def file_type_from_extension(ext)
      nil
    end

    ##
    # Builds sorted array of absolute src paths and stores in @<src_attr_id> instance variable.
    #
    def process_src(src_attr_id, src_ext_attr_id)
      src_attr = @node.get_attr(src_attr_id)
      extensions = @node.get_attr(src_ext_attr_id).value

      file_manager = @services.file_manager
      src = instance_variable_set("@#{src_attr_id}", [])

      spec_files = []

      src_attr.visit_attr do |elem, spec|
        force = elem.has_flag_option?(:force)
        spec_files.clear
        vpath_option = elem.get_option_value(:vpath, fail_if_not_found: false)

        abs_spec = !spec.absolute_path? ? "#{@root}/#{spec}" : spec
        glob_matches = nil

        if spec.wildcard?
          if force
            @services.jaba_error('Wildcards are not allowed when force adding src - ' \
              'only explicitly specified source files', callstack: src_attr.last_call_location)
          end
          glob_matches = file_manager.glob(abs_spec)
        else # else its an explicitly specified file or directory
          if !file_manager.exist?(abs_spec) && !force
            @services.jaba_error("'#{spec}' does not exist on disk. Use :force to add anyway.", callstack: src_attr.last_call_location)
          end

          # If its a directory add files recursively, else add single file
          #          
          if File.directory?(abs_spec)
            glob_matches = file_manager.glob("#{abs_spec}/**/*")
          else
            spec_files << abs_spec
          end
        end

        if glob_matches
          if glob_matches.empty?
            @services.jaba_warning("'#{spec}' did not match any #{src_attr_id} files ", callstack: src_attr.last_call_location)
          else
            matching = glob_matches.select{|f| extensions.include?(f.extname)}
            # It is valid for matching to be empty here, eg if file type is not wanted on this platfom
            spec_files.concat(matching)
          end
        end

        spec_files.each do |f|
          bs = want_backslashes? # Does this project require backslashes (eg Visual Studio)
          
          vpath = if vpath_option
            vpath_option
          else
            # vpath must not actually contain any ..
            #
            f.dirname.relative_path_from(@projroot, backslashes: bs, nil_if_dot: true, no_dot_dot: true)
          end

          sf = SourceFile.new
          sf.absolute_path = f
          sf.projroot_rel = f.relative_path_from(@projroot, backslashes: bs)
          sf.vpath = vpath
          sf.file_type = file_type_from_extension(f.extname)

          src << sf
        end
      end

      if src.empty?
        @services.jaba_error("'#{@node.defn_id}' does not have any source files", callstack: @node.definition.source_location)
      end

      src.sort!{|x, y| x.absolute_path.casecmp(y.absolute_path)}
    end

  end

end
