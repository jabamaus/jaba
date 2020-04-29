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
    attr_reader :type_id # eg :cpp, :text

    ##
    #
    def initialize(services, type_id)
      @services = services
      @type_id = type_id
      @nodes = []
      @node_to_project = {}
      init
    end
    
    ##
    #
    def make_node(**options, &block)
      node = @services.make_node(**options, &block)
      @nodes << node
      node
    end

    ##
    # Override this in subclass.
    #
    def init
      # nothing
    end

    ##
    # Override this to split an attribute out into an anonyomous type. Use when splitting a definition into
    # a tree of nodes.
    #
    def sub_type(attr_id)
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
        @services.jaba_error("'#{node}' not found")
      end
      p
    end
    
    ##
    # Override this in subclass.
    #
    def dump_jaba_output(g_root)
    end

  end
  
end
