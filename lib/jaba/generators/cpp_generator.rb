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
    # TODO: system for ensuring all attributes are 'handled'?
    def make_nodes
      root_node = make_node(handle: nil, attrs: [:root, :platforms])
      
      root_node.attrs.platforms.each do |platform|
        hosts_node = make_node(handle: nil, parent: root_node, attrs: [:platform, :hosts]) do |n|
          n.attrs.platform platform
        end
        
        hosts_node.attrs.hosts.each do |host|
          project_node = make_node(handle: "cpp|#{@jaba_type.type}|#{platform}|#{host}", parent: hosts_node, attrs: [:name, :namesuffix, :host, :src, :targets, :vcglobal]) do |n|
            n.attrs.host host
          end
          
          #@projects << make_project(Vcxproj, project_node)
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
