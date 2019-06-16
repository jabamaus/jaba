# frozen_string_literal: true

require 'tsort'

##
#
module JABA

  ##
  #
  module OS
    
    ##
    #
    def self.windows?
      true
    end
    
    ##
    #
    def self.mac?
      false
    end
    
  end

  ##
  #
  class CyclicDependency < StandardError; end
  
  ##
  #
  class TSorter
    include TSort
    
    ##
    #
    def initialize(nodes, child_nodes)
      @nodes = nodes
      @child_nodes = child_nodes
    end

    ##
    #
    def tsort_each_node(&block)
      @nodes.each(&block)
    end
    
    ##
    #
    def tsort_each_child(node, &block)
      node.send(@child_nodes).each(&block)
    end
    
    ##
    #
    def sort
      result = []
      each_strongly_connected_component do |c|
        if c.size == 1
          result << c.first
        else
          e = CyclicDependency.new
          e.instance_variable_set(:@err_obj, c.first)
          raise e
        end
      end
      result
    end

  end

  ##
  #
  class StringWriter
    
    attr_reader :str
    
    ##
    #
    def initialize(capacity:)
      @buffers = []
      @str = String.new(capacity: capacity)
      @buffers << @str
    end
    
    ##
    #
    def write(str)
      @str << str << "\n"
    end
    
    ##
    #
    def write_raw(str)
      @str << str
    end
  
    ##
    # `
    def newline
      @str << "\n"
    end
    
    ##
    #
    def sub_buffer(capacity: 4096)
      @str = String.new(capacity: capacity)
      @buffers << str
      yield
      sb = @str
      @buffers.pop
      @str = @buffers.last
      sb
    end
    
  end
  
end
