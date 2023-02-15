module JABA
  class AttributeBase
    def initialize(attr_def, node)
      @attr_def = attr_def
      @node = node
      @set = false
    end
    def set? = @set
  end
  
  class AttributeElement < AttributeBase
    def initialize(attr_def, node)
      super
      @value = nil
    end
    def value = @value
    def set(*args)
      new_value = args.shift
      @value = new_value
      @set = true
    end
  end

  class AttributeSingle < AttributeElement
    def initialize(attr_def, node)
      super
    end
  end
end