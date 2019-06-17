# frozen_string_literal: true

module JABA

  ##
  # Base class for instances of projects, eg a Visual Studio project/Xcode project/makefile etc.
  #
  class Project
    
    ##
    #
    def initialize(node)
      @node = node
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
    
    ##
    #
    def generate
      puts "Generating #{@node.id}"
    end
    
  end
  
end
