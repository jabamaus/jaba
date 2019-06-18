module JABA

  ##
  #
  class VcxprojGenerator < Generator
    
    ##
    #
    def init
      @projects = []
    end
      
    ##
    #
    def make_nodes
      node = make_node
      @projects << make_project(Vcxproj, node)
    end
    
    ##
    #
    def generate
      @projects.each(&:generate)
    end
    
  end
  
end
