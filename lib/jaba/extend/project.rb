# frozen_string_literal: true

##
#
module JABA

  using JABACoreExt
  
  ##
  # Base class for instances of projects. Definition of project is quite loose.
  #
  class Project
    
    attr_reader :node
    attr_reader :attrs
    attr_reader :root
    
    ##
    #
    def initialize(plugin, node)
      @plugin = plugin
      @node = node
      @attrs = node.attrs
      @root = @attrs.root
    end
    
    ##
    #
    def services
      @plugin.services
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
