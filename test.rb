require 'pp'

class API# < BasicObject
  #include ::PP::ObjectMixin
  #define_method(:is_a?, ::Kernel.method(:is_a?))

  def initialize(s)
    @s = s
    @s.set_api(self)
  end

  #def inspect
  #  ::Kernel.puts 'in inspect'
  #  'yay'
  #end
  def method_missing(type, id, **options, &block)
    #if type == :inspect
      ::Kernel.puts "got #{type}"
      #super
    #else
      @s.register(type, id, **options, &block)
    #end
  end

end

class Services

  def initialize
    @types = []
  end

  def set_api(a)
    @api = a
  end
  def register(type, id, **options, &block)
    @types << [type, id , options, block]
  end

end

s = Services.new
x = s.object_id
a = API.new(s)
str = IO.read("#{__dir__}/lib/jaba/core/types.rb")
a.instance_eval(str)
pp s#.inspect
#pp s
#puts "--------------"
#pp s
puts "done"
