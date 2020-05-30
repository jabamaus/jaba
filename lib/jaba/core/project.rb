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

      dest = instance_variable_set("@#{src_attr_id}", [])

      src_attr.visit_attr do |elem, spec|
        force = elem.has_flag_option?(:force)
        if force && spec =~ /\*/
          @services.jaba_error('Wildcards are not allowed when force adding src - ' \
            'only explicitly specified source files', callstack: src_attr.last_call_location)
        end
        src_files = @services.file_manager.files_from_spec("#{@root}/#{spec}", extensions, force: force)
        if src_files.empty?
          @services.jaba_warning("'#{spec}' did not match any #{src_attr_id} files " \
            "(could be a case sensitivity issue)", callstack: src_attr.last_call_location)
        else
          src_files.each do |f|
            dest << f
          end
        end
      end

      dest.sort_no_case!
      dest.map!{|f| f.relative_path_from(@projroot)}

    end

  end

end
