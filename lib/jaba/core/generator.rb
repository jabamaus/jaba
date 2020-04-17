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
    def initialize(services, jaba_type)
      @services = services
      @jaba_type = jaba_type
      @nodes = []
      @node_to_project = {}
    end
    
    ##
    #
    def set_attr_tracker(*args)
      @services.set_attr_tracker(*args)
    end
    
    ##
    #
    def make_node(**options, &block)
      node = @services.make_node(**options, &block)
      @nodes << node
      node
    end
    
    ##
    # Override this in sublcass if type needs to be split into more than one node.
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
      setup_project(p)
      p
    end
    
    ##
    # Override this in subclass.
    #
    def setup_project(project)
      # Nothing.
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
