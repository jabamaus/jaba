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
      @node_to_project = {}
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
      p = klass.new(@services, self, node)
      @node_to_project[node] = p
      p.init
      p
    end
    
    ##
    #
    def project_from_node(node, fail_if_not_found: true)
      p = @node_to_project[node]
      if !p && fail_if_not_found
        raise "'#{node}' not found"
      end
      p
    end
    
    ##
    #
    def save_file(filename, content, eol)
      @services.save_file(filename, content, eol)
    end
    
  end
  
end
