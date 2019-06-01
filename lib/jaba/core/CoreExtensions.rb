module JABACoreExtensions

##
#
refine Class do
  
  ##
  # Allow setting and getting a block as a member variable.
  #
  def attr_block(attr)
    self.class_eval "def #{attr}(&block); block_given? ? @#{attr} = block : @#{attr} ; end"
  end
  
end

##
#
refine Object do

  ##
  #
  def boolean?
    (is_a?(TrueClass) or is_a?(FalseClass))
  end
  
end

##
#
refine String do

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
refine Hash do

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

end
