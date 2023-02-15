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
      #if attr_def.default_set? && !@default_block
      #  set(attr_def.default, call_on_set: false)
      #end
    end
  end
end