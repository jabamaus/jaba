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
  class SingleNodeAttributeDefinitionTracker
  
    attr_reader :jaba_type

    ##
    #
    def initialize
      @jaba_type = nil
      @all_attr_defs = []
    end

    ##
    #
    def set_jaba_type(jt)
      if jt != @jaba_type
        @jaba_type = jt
        @all_attr_defs.clear
        jt.iterate_attr_defs {|ad| @all_attr_defs << ad}
      end
    end

    ##
    #
    def use_attrs(attr_def_ids)
      # nothing
    end

    ##
    #
    def iterate_attr_defs(&block)
      @all_attr_defs.each(&block)
    end

    ##
    #
    def check_all_handled
      # nothing, because being a single node they are all handled by definition
    end

  end

  ##
  #
  class MultiNodeAttributeDefinitionTracker

    attr_reader :jaba_type

    ##
    #
    def initialize
      @jaba_type = nil
      @all_attr_defs = []
      @current_attr_defs = []
      @handled_tracker = {}
    end

    ##
    #
    def set_jaba_type(jt)
      @current_attr_defs.clear
      @handled_tracker.clear
      
      if jt != @jaba_type
        @jaba_type = jt
        @all_attr_defs.clear
        jt.iterate_attr_defs {|ad| @all_attr_defs << ad}
      end

      @all_attr_defs.each {|ad| @handled_tracker[ad] = false}
    end

    ##
    #
    def use_attrs(attr_def_ids)
      #if @handled_tracker.size == @attr_defs.size
      #  raise "All attributes have already been handled!"
      #end
      
      @current_attr_defs.clear

      if attr_def_ids
        attr_def_ids.each do |id|
          ad = @jaba_type.get_attr_def(id)
          @current_attr_defs << ad
          @handled_tracker[ad] = true
        end
      else
        @handled_tracker.each do |ad, handled|
          if !handled
            @current_attr_defs << ad
            @handled_tracker[ad] = true
          end
        end
      end
    end

    ##
    #
    def iterate_attr_defs(&block)
      @current_attr_defs.each(&block)
    end

    ##
    #
    def check_all_handled
      #if !@remaining.empty?
      #  @jaba_type.jaba_error("#{@remaining.map(&:id)} attribute(s) in '#{@jaba_type.type_id}' type not handled")
      #end
    end

  end

end
