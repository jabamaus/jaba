##
#
class Class
  
  ##
  # Allow setting and getting a block as a member variable.
  #
  def attr_block(*attrs)
    attrs.each do |a|
      self.class_eval "def #{a}(&block); block_given? ? @#{a} = block : @#{a} ; end"
    end
  end
  
  ##
  # Defines a boolean attribute(s). Boolean member variable must be initialised.
  #
  def attr_boolean(*attrs)
    attrs.each do |a|
      self.class_eval("def #{a}?; @#{a}; end")
      self.class_eval("def #{a}=(val); @#{a}=val; end")
    end
  end
  
end

##
#
class String

  ##
  #
  def basename
    File.basename(self)
  end
  
  ##
  #
  def capitalize_first!
    self[0] = self[0].chr.upcase
    self
  end

  ##
  #
  def capitalize_first
    dup.capitalize_first!
  end
  
end

##
#
class Hash

  ##
  # Appends value to array referenced by key, creating array if it does not exist. Value being passed in can be a single value or array.
  # Existing key can be optionally cleared.
  #
  def push_value(key, value, clear: false)
    v = self[key] = self.fetch(key, [])
    v.clear if clear
    value.is_a?(Array) ? v.concat(value) : v << value
    self
  end
  
end

module JABA

##
#
class Hooks
  
  ##
  #
  def initialize
    @hooks = {}
  end
  
  ##
  #
  def define_hook(id, override: false, &block)
    @hooks.push_value(id, block, clear: override)
  end
  
  ##
  #
  def hook_defined?(id)
    @hooks.key?(id)
  end
  
  ##
  #
  def call_hook(id, *args, receiver: self)
    result = nil
    hooks = @hooks[id]
    if hooks
      hooks.each do |hook|
        result = receiver.instance_exec(*args, &hook)
      end
    else
      raise "'#{id}' hook undefined"
    end
    result
  end
  
end

end
