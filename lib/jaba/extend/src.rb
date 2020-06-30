# frozen_string_literal: true

##
#
module JABA

  using JABACoreExt
  
  SourceFile = Struct.new(:absolute_path, :projroot_rel, :vpath, :file_type)
  
  # Include in projects that require src files. Requires @node, @root and @projroot to be set
  #
  module SrcFileSupport

    ##
    # Override in subclass if project format uses backslashes (eg Visual Studio)
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
      if !defined?(@node)
        raise "process_src requires @node instance variable to be set"
      end
      services = @node.services
      if !defined?(@root)
        services.jaba_error("process_src requires @root instance variable to be set")
      end
      if !defined?(@projroot)
        services.jaba_error("process_src requires @projroot instance variable to be set")
      end

      src_attr = @node.get_attr(src_attr_id)
      extensions = @node.get_attr(src_ext_attr_id).value

      file_manager = services.file_manager
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
            services.jaba_error('Wildcards are not allowed when force adding src - ' \
              'only explicitly specified source files', callstack: src_attr.last_call_location)
          end
          glob_matches = file_manager.glob(abs_spec)
        else # else its an explicitly specified file or directory
          if !file_manager.exist?(abs_spec) && !force
            services.jaba_error("'#{spec}' does not exist on disk. Use :force to add anyway.", callstack: src_attr.last_call_location)
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
            services.jaba_warning("'#{spec}' did not match any #{src_attr_id} files ", callstack: src_attr.last_call_location)
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
        services.jaba_error("'#{@node.defn_id}' does not have any source files", callstack: @node.definition.src_loc_raw)
      end

      src.sort!{|x, y| x.absolute_path.casecmp(y.absolute_path)}
    end

  end

end