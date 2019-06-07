# frozen_string_literal: true

module JABA

  ##
  # Base class for instances of projects, eg a Visual Studio project/Xcode project/makefile etc.
  #
  class Project
    
    ##
    #
    def initialize(node)
    end
    
  end

  ##
  #
  class Vcxproj < Project
    
    ##
    #
    def initialize(node)
      super
      
    end
    
  end
  
end
