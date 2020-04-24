# frozen_string_literal: true

##
#
module JABA

  using JABACoreExt
  
  ##
  # Base class for instances of projects, eg a Visual Studio project/Xcode project/makefile etc.
  #
  class Project
    
    attr_reader :node
    attr_reader :attrs
    attr_reader :root
    attr_reader :genroot
    
    ##
    #
    def initialize(services, generator, node)
      @services = services
      @generator = generator
      @node = node
      @attrs = node.attrs
      r = @attrs.root
      @root = r.absolute_path? ? r : "#{node.source_dir}/#{r}"
      @genroot = "#{@root}/#{@attrs.genroot}"
      @proj_root = "#{@genroot}/#{@attrs.projname}".cleanpath
    end
    
    ##
    #
    def handle
      @node.handle
    end

    ##
    # Override this in subclass and call super
    #
    def dump_jaba_output(p_root)
      p_root[:genroot] = @genroot
    end

  end

end
