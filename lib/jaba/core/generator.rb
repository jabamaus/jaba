# frozen_string_literal: true

##
#
module JABA

  using JABACoreExt
  
  ##
  #
  class Generator
    
    ##
    #
    def initialize
      @nodes = []
    end
    
    ##
    #
    def make_node(**options, &block)
      node = @services.make_node(**options, &block)
      @nodes << node
      node
    end
    
    ##
    #
    def make_nodes
      make_node
    end
    
    ##
    #
    def make_project(klass, node)
      p = klass.new(node)
      p.instance_variable_set(:@services, @services)
      p.init
      p
    end
    
    ##
    #
    def save_file(filename, content, eol)
      @services.save_file(filename, content, eol)
    end
    
  end
  
end
