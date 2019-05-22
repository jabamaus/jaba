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
  
end

##
#
class Object

  ##
  #
  def boolean?
    (is_a?(TrueClass) or is_a?(FalseClass))
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

end
