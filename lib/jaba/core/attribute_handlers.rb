# frozen_string_literal: true

##
#
module JABA

  using JABACoreExt
  
  ##
  #
  class AttributeHandler
    
    ##
    #
    def init_attr_def(d)
    end
    
    ##
    #
    def validate_attr_def(d)
    end
    
    ##
    #
    def validate_value(d, v)
    end
    
  end
  
  ##
  #
  class HandlerDefault < AttributeHandler
  end
  
  ##
  #
  class HandlerBool < AttributeHandler

    ##
    #
    def init_attr_def(d)
      d.set_var :default, false
      d.set_var :flags, [:unordered, :allow_dupes]
    end
    
    ##
    #
    def validate_value(d, v)
      if !v.boolean?
        @services.jaba_error ':bool attributes only accept [true|false]', callstack: d.api_call_line
      end
    end
    
  end
  
  ##
  #
  class HandlerChoice < AttributeHandler
  
    ##
    #
    def init_attr_def(d)
      d.set_var :items, []
    end
    
    ##
    #
    def validate_attr_def(d)
      if d.get_var(:items).empty?
        @services.jaba_error "'items' must be set", callstack: d.api_call_line
      end
    end
    
    ##
    #
    def validate_value(d, v)
      items = d.get_var(:items)
      if !items.include?(v)
        @services.jaba_error "must be one of #{items}", callstack: d.api_call_line
      end
    end
  
  end
  
  ##
  #
  class HandlerDir < AttributeHandler
  end
  
  ##
  #
  class HandlerFile < AttributeHandler
  end
  
  ##
  #
  class HandlerPath < AttributeHandler
  end
  
  ##
  #
  class HandlerKeyValue < AttributeHandler
  
    ##
    #
    def init_attr_def(d)
      d.set_var :default, KeyValue.new
    end
    
  end
  
  ##
  #
  class HandlerReference < AttributeHandler
    
    ##
    #
    def init_attr_def(d)
      d.set_var :referenced_type, nil
    end
    
    ##
    #
    def validate_attr_def(d)
      rt = d.get_var(:referenced_type)
      if rt.nil?
        @services.jaba_error "'referenced_type' must be set", callstack: d.api_call_line
      end
      if d.jaba_type.type != rt
        d.jaba_type.set_var :dependencies, rt
      end
    end
      
  end

end
