##
#
class Class
  
  ##
  # Allow setting and getting a block as a member variable.
  #
  def attr_block(*attrs)
    attrs.each do |a|
      self.class_eval "def #{a}(&block); block_given? ? @#{a}_block = block : @#{a}_block ; end"
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
  
end
