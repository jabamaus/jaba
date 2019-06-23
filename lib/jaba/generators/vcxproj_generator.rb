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
      proj_node = make_node
      proj = make_project(Vcxproj, proj_node)
      @projects << proj
      proj_node.attrs.configs.each do |cfg|
        make_node(handle: nil, parent: proj_node, attrs: [:config, :vcproperty]) do |n|
          n.attrs.config cfg
        end
      end
    end
    
    ##
    #
    def generate
      @projects.each(&:generate)
    end
    
  end
  
end
