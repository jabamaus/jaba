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

    ##
    #
    def set_property(var_name, val = nil, &block)
      if block_given?
        if !val.nil?
          @services.jaba_error('Must provide a default value or a block but not both')
        end
        instance_variable_set("@#{var_name}", block)
      else
        if !instance_variable_defined?("@#{var_name}")
          instance_variable_set("@#{var_name}", val)
        else
          var = instance_variable_get("@#{var_name}")
          if var.is_a?(Array)
            var.concat(Array(val))
          else
            instance_variable_set("@#{var_name}", val)
          end
        end
      end
    end
    
    ##
    #
    def get_property(var_name)
      instance_variable_get("@#{var_name}")
    end
    
    ##
    #
    def handle_property(id, val, &block)
      if !instance_variable_defined?("@#{id}")
        @services.jaba_error("'#{id}' property not defined")
      end
      if val.nil?
        get_property(id)
      else
        set_property(id, val, &block)
      end
    end
    
  end
  
  ##
  #
  class AttributeDefinitionTrackerBase

    attr_reader :jaba_type

    ##
    #
    def set_jaba_type(jt)
      @jaba_type = jt
      @attr_defs = []
    end

    ##
    #
    def iterate_attr_defs(&block)
      @attr_defs.each(&block)
    end

    ##
    #
    def ignore?(attr_def_id)
      @attr_def_ids.index(attr_def_id) == nil
    end

  end

  ##
  #
  class SingleNodeAttributeDefinitionTracker < AttributeDefinitionTrackerBase
  
    ##
    #
    def set_jaba_type(jt)
      super
      jt.iterate_attr_defs {|ad| @attr_defs << ad} # TODO: put in a cache
    end

    ##
    #
    def use_attrs(attr_def_ids)
      @attr_def_ids = if attr_def_ids
        attr_def_ids
      else
        @attr_defs.map(&:id)
      end
    end

    ##
    #
    def check_all_handled
      # nothing, because being a single node they are all handled by definition
    end

  end

  ##
  #
  class MultiNodeAttributeDefinitionTracker < AttributeDefinitionTrackerBase

    ##
    #
    def set_jaba_type(jt)
      super
      @remaining = []
      jt.iterate_attr_defs {|ad| @remaining << ad} # TODO: put in a cache?
    end

    ##
    #
    def use_attrs(attr_def_ids)
      if attr_def_ids
        if @attr_defs.empty?
          raise "All attributes have already been handled!"
        end
        @attr_def_ids = attr_def_ids
        @attr_defs.clear
        @remaining.delete_if do |ad|
          if attr_def_ids.index(ad.id)
            @attr_defs << ad
            true
          else
            false
          end
        end
      else
        @attr_def_ids = @remaining.map(&:id)
        @attr_defs = @remaining.dup
        @remaining.clear
      end
    end

    ##
    #
    def check_all_handled
      if !@remaining.empty?
        @jaba_type.jaba_error("#{@remaining.map(&:id)} attribute(s) in '#{@jaba_type.type_id}' type not handled")
      end
    end

  end

end
