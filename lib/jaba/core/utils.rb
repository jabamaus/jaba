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
    def <<(str)
      @str << str << "\n"
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
    def chomp!
      @str.chomp!
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
  
  module PropertyMethods

    @@id_to_var = {}

    ##
    #
    def get_var(id)
      v = @@id_to_var[id]
      if !v
        v = "@#{id}"
        @@id_to_var[id] = v
      end
      v
    end

    ##
    #
    def define_property(p_id, val = nil)
      var = get_var(p_id)
      if instance_variable_defined?(var)
        @services.jaba_error("'#{p_id}' property multiply defined")
      end

      instance_variable_set(var, val)
    end

    ##
    #
    def define_array_property(p_id, val = [])
      var = get_var(p_id)
      if instance_variable_defined?(var)
        @services.jaba_error("'#{p_id}' property multiply defined")
      end

      instance_variable_set(var, val)
    end

    ##
    #
    def set_property(p_id, val = nil, &block)
      var = get_var(p_id)
      if !instance_variable_defined?(var)
        @services.jaba_error("'#{p_id}' property not defined")
      end

      if block_given?
        if !val.nil?
          @services.jaba_error('Must provide a default value or a block but not both')
        end
        instance_variable_set(var, block)
      else
        current_val = instance_variable_get(var)
        if current_val.is_a?(Array)
          if val.is_a?(Array)
            val.flatten!
            on_property_set(p_id, var, val)
            current_val.concat(val)
          else
            on_property_set(p_id, var, val)
            current_val << val
          end
        else
          instance_variable_set(var, val)
        end
      end
    end
    
    ##
    # Override in subclass to validate value.
    #
    def on_property_set(id, var, new_val)
      # nothing
    end

    ##
    #
    def get_property(p_id)
      var = get_var(p_id)
      if !instance_variable_defined?(var)
        @services.jaba_error("'#{p_id}' property not defined")
      end
      instance_variable_get(var)
    end
    
    ##
    #
    def handle_property(p_id, val, &block)
      if val.nil?
        get_property(p_id)
      else
        set_property(p_id, val, &block)
      end
    end
    
  end
  
end
