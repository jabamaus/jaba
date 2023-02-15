module JABA
  class AttributeBase
    def initialize(attr_def, node)
      @attr_def = attr_def
      @node = node
      @set = false
    end
    def attr_def = @attr_def
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
      if !attr_def.get_default.nil? && !attr_def.get_default.proc?
        set(attr_def.get_default)
      end
    end
  end
end