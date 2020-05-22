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
      pr = @attrs.projroot

      # If projroot is specified as an absolute path, use it directly, else prepend 'root', which itself
      # could either be an absolute or relative to the definition source file.
      #
      if pr.absolute_path?
        @projroot = pr
      else
        r = @attrs.root
        r = r.absolute_path? ? r : "#{node.definition.source_dir}/#{r}"
        @projroot = "#{r}/#{pr}"
      end
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

  end

end
