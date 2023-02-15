class Node
  def initialize(api_klass, id, &block)
    @id = id
    puts "Making #{api_klass}"
    api_klass.singleton.__internal_set_node(self)
    #api_klass.singleton.instance_eval(&block)
    api_klass.attr_defs.each do |d|
      puts "  #{d.name}"
    end

  end
  def id = @id
end
