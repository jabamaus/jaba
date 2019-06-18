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
      root_node = make_node(attrs_mask: [:root, :platforms])
      root_node.attrs.platforms.each do |p|
        platform_hosts_node = make_node(parent: root_node, attrs_mask: [:platform, :hosts]) {|n| n.attrs.platform p}
        platform_hosts_node.attrs.hosts.each do |h|
          project_node = make_node(parent: platform_hosts_node, attrs_mask: [:name, :namesuffix, :host, :src, :targets, :vcglobal]) {|n| n.attrs.host h}
          project = make_project(Vcxproj, project_node)
          @projects << project
          project.attrs.targets.each do |t|
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
