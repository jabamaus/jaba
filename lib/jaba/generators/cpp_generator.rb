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
      @project_nodes = []
      @projects = []
    end
    
    ##
    #
    def sub_type(attr_id)
      case attr_id
      when :root, :platforms
        :cpp_root
      when :platform, :hosts
        :cpp_hosts
      end
    end

    ##
    #
    def make_nodes
      root_node = make_node(type_id: :cpp_root,
                            id: "#{current_id}_root",
                            handle: nil)
      
      root_node.attrs.platforms.each do |p|
        hosts_node = make_node(type_id: :cpp_hosts,
                               id: "#{current_id}_hosts",
                               handle: nil,
                               parent: root_node) do
          platform p
        end
        
        hosts_node.attrs.hosts.each do |h|
          proj_node = make_node(type_id: :cpp,
                                id: "#{current_id}_project",
                                handle: "cpp|#{current_id}|#{p.id}|#{h.id}",
                                parent: hosts_node) do
            host h
          end

          @project_nodes << proj_node
          
          proj_node.attrs.configs.each do |cfg|
            make_node(type_id: :vsconfig,
                      id: "cpp_#{current_id}_config_#{cfg}",
                      handle: nil,
                      parent: proj_node) do
              config cfg
            end
          end
        end
      end
    end
    
    ##
    #
    def setup_project(proj)
      proj.attrs.instance_eval do
        vcglobal :ProjectGuid, proj.guid
        vcglobal :WindowsTargetPlatformVersion, winsdkver
      end
      
      proj.configs.each do |cfg|
        cfg.attrs.instance_eval do
          config_type = case type
                        when :app
                          'Application'
                        when :lib
                          'StaticLibrary'
                        when :dll
                          'DynamicLibrary'
                        else
                          raise "'#{type}' unhandled"
                        end
          vcproperty :ConfigurationType, config_type, group: :pg1
          vcproperty :PlatformToolset, toolset, group: :pg1
          vcproperty :RuntimeTypeInfo, false, group: :ClCompile if !rtti
        end
      end
    end
    
    ##
    #
    def generate
      @project_nodes.each do |pn|
        @projects << make_project(Vcxproj, pn)
      end
      @projects.each(&:generate)
    end
    
  end
  
end
