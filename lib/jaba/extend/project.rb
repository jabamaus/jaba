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
    
    attr_reader :node
    attr_reader :attrs
    attr_reader :projroot
    attr_reader :projname
    
    ##
    #
    def initialize(generator, node, root)
      @generator = generator # required in order to look up other projects when resolving dependencies
      @node = node
      @root = root
      @attrs = node.attrs
      @projroot = @attrs.projroot
      @projname = @attrs.projname
    end
    
    ##
    #
    def services
      @generator.services
    end

    ##
    # eg MyApp|vs2019|windows
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

  end

end
