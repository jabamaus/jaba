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
      r = r.absolute_path? ? r : "#{node.source_dir}/#{r}"
      @projroot = "#{r}/#{@attrs.projroot}"
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
