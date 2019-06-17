# frozen_string_literal: true

module JABA

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
    def save_file(filename, content, eol)
      @services.save_file(filename, content, eol)
    end
    
  end
  
end
