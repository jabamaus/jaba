# frozen_string_literal: true

require 'fiddle'
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
    
    ##
    #
    def self.generate_guid
      if windows?
        result = ' ' * 16
        rpcrt4 = Fiddle.dlopen('rpcrt4.dll')
        uuid_create = Fiddle::Function.new(rpcrt4['UuidCreate'], [Fiddle::TYPE_VOIDP], Fiddle::TYPE_LONG)
        uuid_create.call(result)
        sprintf('{%04X%04X-%04X-%04X-%04X-%04X%04X%04X}', *result.unpack('SSSSSSSS')).upcase
      else
        raise 'generate_guid not implemented on this platform'
      end
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
  class StringWriter < String
    
    ##
    #
    def <<(str)
      concat str, "\n"
    end
    
    ##
    #
    def write_raw(str)
      concat str
    end
  
    ##
    #
    def newline
      concat "\n"
    end
    
  end
  
end
