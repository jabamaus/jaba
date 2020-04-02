# frozen_string_literal: true

module JABA

  # The classes in this file are only needed by the user if extending the core functionality of Jaba.

  ##
  #
  module TopLevelExtensionAPI

    ##
    #
    def attr_type(id, &block)
      @obj.define_attr_type(id, &block)
    end
    
    ##
    #
    def attr_flag(id)
      @obj.define_attr_flag(id)
    end
    
    ##
    #
    def define(type, **options, &block)
      @obj.define_type(type, **options, &block)
    end
    
    ##
    #
    def open(type, &block)
      @obj.open_type(type, &block)
    end
    
  end

end
