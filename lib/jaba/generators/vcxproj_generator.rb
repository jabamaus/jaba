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
      @projects << Vcxproj.new(node)
    end
    
    ##
    #
    def generate
      @projects.each do |p|
        p.generate
      end
    end
    
  end
  
end
