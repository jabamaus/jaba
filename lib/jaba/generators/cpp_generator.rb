module JABA

  ##
  #
  class CppGenerator < Generator
    
    ##
    #
    def init
      @projects = []
    end
      
    ##
    #
    def make_nodes
      root_node = make_node(attrs: [:root, :platforms])
      
      root_node.attrs.platforms.each do |p|
        hosts_node = make_node(parent: root_node, attrs: [:platform, :hosts]) do |n|
          n.attrs.platform p
        end
        
        hosts_node.attrs.hosts.each do |h|
          project_node = make_node(parent: hosts_node, attrs: [:name, :namesuffix, :host, :src, :targets, :vcglobal]) do |n|
            n.attrs.host h
          end
          
          project = make_project(Vcxproj, project_node)
          @projects << project
          project_node.attrs.targets.each do |t|
          end
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
