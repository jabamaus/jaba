# frozen_string_literal: true

##
#
module JABA

  using JABACoreExt
  
  # Include in projects that require src files. Requires @node, @root and @projdir to be set
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
        JABA.error("process_src requires @node instance variable to be set")
      end
      services = @node.services
      if !defined?(@root)
        JABA.error("process_src requires @root instance variable to be set")
      end
      if !defined?(@projdir)
        JABA.error("process_src requires @projdir instance variable to be set")
      end

      src_attr = @node.get_attr(src_attr_id)
      extensions = @node.get_attr(src_ext_attr_id).value

      file_manager = services.file_manager
      src = instance_variable_set("@#{src_attr_id}", [])
      src_lookup = {}

      spec_files = []

      src_attr.visit_attr do |elem, abs_path|
        force = elem.has_flag_option?(:force)
        spec_files.clear
        vpath_option = elem.get_option_value(:vpath, fail_if_not_found: false)
        glob_matches = nil

        if abs_path.wildcard?
          if force
            JABA.error('Wildcards are not allowed when force adding src - ' \
              'only explicitly specified source files', errobj: elem)
          end
          glob_matches = file_manager.glob(abs_path)
        else # else its an explicitly specified file or directory
          if !file_manager.exist?(abs_path) && !force
            JABA.error("'#{abs_path}' does not exist on disk. Use :force to add anyway.", errobj: elem)
          end

          # If its a directory add files recursively, else add single file
          #          
          if File.directory?(abs_path)
            glob_matches = file_manager.glob("#{abs_path}/**/*")
          else
            spec_files << abs_path
          end
        end

        if glob_matches
          if glob_matches.empty?
            services.jaba_warn("'#{abs_path}' did not match any #{src_attr_id} files ", errobj: elem)
          else
            extname = abs_path.extname
            # Glob matches will ignore files of unwanted extensions, unless the extension is explicitly specified
            #
            if !extname.empty? && !extname.wildcard?
              spec_files.concat(glob_matches)
            else
              matching = glob_matches.select{|f| extensions.include?(f.extname)}
              # It is valid for matching to be empty here, eg if file type is not wanted on this platfom
              spec_files.concat(matching)
            end
          end
        end

        spec_files.each do |f|
          # Different specs could match the same file so ignore duplicates
          next if src_lookup.key?(f)
          src_lookup[f] = true

          bs = want_backslashes? # Does this project require backslashes (eg Visual Studio)
          
          vpath = if vpath_option
            vpath_option
          else
            # If no specified vpath then preserve the structure of the src files/folders. 
            # It is important that vpath does not start with ..
            #
            f.dirname.relative_path_from(@root, backslashes: bs, nil_if_dot: true, no_dot_dot: true)
          end

          sf = OpenStruct.new
          sf.absolute_path = f
          sf.projdir_rel = f.relative_path_from(@projdir, backslashes: bs)
          sf.vpath = vpath
          sf.file_type = file_type_from_extension(f.extname)

          src << sf
        end
      end

      if src.empty?
        JABA.error("#{@node.describe} does not have any source files", errobj: @node)
      end

      src.sort!{|x, y| x.absolute_path.casecmp(y.absolute_path)}
    end

    ##
    #
    def get_matching_src_objs(spec, src_list, fail_if_not_found: true, errobj: nil)
      abs_spec = JABA.spec_to_absolute_path(spec, @root, @node)
      if abs_spec.wildcard?
        src_list.select{|s| File.fnmatch?(abs_spec, s.absolute_path)}
      else
        s = src_list.find{|s| s.absolute_path == abs_spec}
        if !s && fail_if_not_found
          JABA.error("'#{spec}' src file not in project", errobj: errobj)
        end
        Array(s)
      end
    end

  end

end
