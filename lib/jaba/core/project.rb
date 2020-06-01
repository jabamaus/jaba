# frozen_string_literal: true

##
#
module JABA

  using JABACoreExt
  
  ##
  # Base class for instances of projects, eg a Visual Studio project/Xcode project/makefile etc.
  #
  class Project
    
    attr_reader :attrs
    attr_reader :projroot
    attr_reader :projname
    
    ##
    #
    def initialize(services, generator, node)
      @services = services
      @generator = generator # required in order to look up other projects when resolving dependencies
      @node = node
      @attrs = node.attrs

      r = @attrs.root
      @root = r.absolute_path? ? r : "#{node.definition.source_dir}/#{r}"

      # If projroot is specified as an absolute path, use it directly, else prepend 'root', which itself
      # could either be an absolute or relative to the definition source file.
      #
      pr = @attrs.projroot
      @projroot = pr.absolute_path? ? pr : "#{@root}/#{pr}"

      @projname = @attrs.projname
    end
    
    ##
    #
    def handle
      @node.handle
    end

    ##
    # Override this in subclass.
    #
    def dump_jaba_output(p_root)
      # nothing
    end

    ##
    #
    def process_src(src_attr_id, src_ext_attr_id)
      src_attr = @node.get_attr(src_attr_id)
      extensions = @node.get_attr(src_ext_attr_id).value.to_set

      file_manager = @services.file_manager
      dest = instance_variable_set("@#{src_attr_id}", [])

      src_attr.visit_attr do |elem, spec|
        force = elem.has_flag_option?(:force)
        wildcard = spec =~ /\*/ ? true : false
        abs_spec = !spec.absolute_path? ? "#{@root}/#{spec}" : spec
        glob_matches = nil

        if wildcard
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
            dest << abs_spec
          end
        end

        if glob_matches
          if glob_matches.empty?
            @services.jaba_warning("'#{spec}' did not match any #{src_attr_id} files ", callstack: src_attr.last_call_location)
          else
            glob_matches.select!{|f| extensions.include?(f.extname)}
            dest.concat(glob_matches)
          end
        end
      end

      if dest.empty?
        @services.jaba_error("'#{@node.definition_id}' does not have any source files", callstack: @node.definition.source_location)
      end

      dest.sort_no_case!
      dest.map!{|f| f.relative_path_from(@projroot)}
    end

  end

end
