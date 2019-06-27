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
      
      root_node.attrs.platforms.each do |p|
        hosts_node = make_node(handle: nil, parent: root_node, attrs: [:platform, :hosts]) do |n|
          platform p
        end
        
        hosts_node.attrs.hosts.each do |h|
          proj_node = make_node(handle: "#{@jaba_type.type}|#{root_node.id}|#{p.id}|#{h.id}",
                                   parent: hosts_node, attrs: [:name, :namesuffix, :host, :src, :configs, :deps, :type, :vcglobal, :winsdkver]) do |n|
            host h
          end
          
          proj_node.attrs.configs.each do |cfg|
            make_node(handle: nil, parent: proj_node, attrs: [:config, :rtti, :vcproperty]) do |n|
              config cfg
            end
          end
          
          @projects << make_project(Vcxproj, proj_node)
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
      @projects.each(&:generate)
    end
    
  end
  
end
