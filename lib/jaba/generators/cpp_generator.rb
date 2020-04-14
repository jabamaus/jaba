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
    #
    def make_nodes

      # Allows multiple nodes to be created from :cpp type, each one handling a different subset of its attributes
      #
      set_attr_tracker(:cpp, :multi_node)

      root_node = make_node(handle: nil, attrs: [:root, :platforms])
      
      root_node.attrs.platforms.each do |p|
        hosts_node = make_node(handle: nil, parent: root_node, attrs: [:platform, :hosts]) do
          platform p
        end
        
        hosts_node.attrs.hosts.each do |h|

          # No explicit attrs passed in so all the remaining unhandled attributes will be used.
          #
          proj_node = make_node(handle: "#{@jaba_type.type_id}|#{root_node.id}|#{p.id}|#{h.id}", parent: hosts_node) do
            host h
          end
          
          set_attr_tracker(:vsconfig, :single_node)

          proj_node.attrs.configs.each do |cfg|
            make_node(id: cfg, handle: nil, parent: proj_node) do
              config cfg
            end
          end

          set_attr_tracker(:cpp, :multi_node)
          
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
