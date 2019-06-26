# frozen_string_literal: true

##
#
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
          proj_node = make_node(handle: "#{@jaba_type.type}|#{root_node.id}|#{platform.id}|#{host.id}",
                                   parent: hosts_node, attrs: [:name, :namesuffix, :host, :src, :configs, :deps, :type, :vcglobal]) do |n|
            n.attrs.host host
          end
          proj = make_project(Vcxproj, proj_node)
          @projects << proj
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
