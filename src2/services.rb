require_relative '../../jrf/jrf/core_ext'

class String
  def split_jdl_path
    if self !~ /\|/
      [nil, self]
    else
      [sub(/\|(\w+)$/, ''), Regexp.last_match(1)]
    end
  end
end

module JABA

class JDLDefinition
  def initialize
    @title = nil
  end
  def services = @services
  def title(t) = @title = t
end

class JDLMethodDefinition < JDLDefinition
  def initialize
    super
    @on_called = nil
  end
  def on_called(&block) = @on_called = block
end

class JDLAttributeDefinition < JDLDefinition
  def initialize
    super
    @flags = nil
  end
  def flags(*flags) = @flags = flags
end

# JDLBase is the blankest possible slate
class JDLBase < BasicObject
  undef_method(:!)
  undef_method(:!=)
  undef_method(:==)
  undef_method(:equal?)
  undef_method(:__id__)
  undef_method(:__send__)
  undef_method(:instance_exec)
end

class Attribute
end

class Node
  def initialize(id)
    @id = id
    @attrs = []
  end
  def id = @id
end

class Services

  def initialize
    @method_path_to_block = {}
    @node_path_to_block = {}
    @attr_path_to_block = {}
    @nodes = []
  end

  def run
    debug! if ARGV.include?('-d')
    jdl_file = "#{__dir__}/jdl.rb"
    str = IO.read(jdl_file)
    instance_eval(str, jdl_file)

    @top_level_klass = JABA.const_set('TopLevelAPI', Class.new(JDLBase))

    services = self
    @node_path_to_block.each do |path, block|
      node_api_klass = api_class_from_path(path, create: true)
      parent_path, item = path.split_jdl_path
      parent_klass = api_class_from_path(parent_path)
      parent_klass.define_method(item) do |*args, **kwargs, &node_block|
        id = args.shift
        services.create_node(node_api_klass, id, &node_block)
      end
    end

    @attr_path_to_block.each do |path, block|
      parent_path, attr_name = path.split_jdl_path
      klass = api_class_from_path(parent_path)
      attr_def = JDLAttributeDefinition.new
      attr_def.instance_variable_set(:@services, self)
      attr_def.instance_eval(&block)
      klass.define_method(attr_name) do |*args, **kwargs|
        attr_def
      end
    end

    @method_path_to_block.each do |path, block|
      parent_path, method_name = path.split_jdl_path
      klass = api_class_from_path(parent_path)
      meth_def = JDLMethodDefinition.new
      meth_def.instance_variable_set(:@services, self)
      meth_def.instance_eval(&block)
      klass.define_method(method_name) do |*args, **kwargs|
        meth_def.instance_variable_get(:@on_called).call(*args, **kwargs)
      end
    end

    # Dump API classes
    JABA.constants.sort.each do |c|
      if c.end_with?('API')
        klass = JABA.const_get(c)
        puts klass
        klass.instance_methods.sort.each do |m|
          next if m == :instance_eval
          puts "  #{m}"
        end
      end
    end

    str = IO.read("#{__dir__}/build.jaba")
    top_level = @top_level_klass.new
    top_level.instance_eval(str, "#{__dir__}/build.jaba")
  end

  def api_class_from_path(path, create: false)
    if path.nil?
      return @top_level_klass
    end
    name = "#{path.split('|').map{|p| p.capitalize_first}.join}API"
    if create
      klass = Class.new(JDLBase)
      klass.class_eval do
        def self.singleton ; @instance ||= self.new ; end
      end
      JABA.const_set(name, klass)
    else
      JABA.const_get(name)
    end
  end

  def node(*paths, &block)
    paths.each do |p|
      @node_path_to_block[p] = block
    end
  end

  def attr(*paths, type: nil, &block)
    paths.each do |p|
      @attr_path_to_block[p] = block
    end
  end

  def method(*paths, &block)
    paths.each do |p|
      @method_path_to_block[p] = block
    end
  end

  def create_node(api_klass, id, &block)
    node = Node.new(id)
    api_node = api_klass.singleton

    @nodes << node
  end

  def register_shared(id, &block)
  end

  def include_shared(id)
  end

end
end

if __FILE__ == $PROGRAM_NAME
  JABA::Services.new.run
end
