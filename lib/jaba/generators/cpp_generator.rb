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
      root_node = make_node(type_id: :cpp_root)
      
      root_node.attrs.platforms.each do |p|
        hosts_node = make_node(type_id: :cpp_hosts, name: p, parent: root_node) do
          platform p
        end
        
        hosts_node.attrs.hosts.each do |h|
          proj_node = make_node(type_id: :cpp, name: h, parent: hosts_node) do
            host h
          end

          @project_nodes << proj_node
          
          proj_node.attrs.configs.each do |cfg|
            make_node(type_id: :cpp_config, name: cfg, parent: proj_node) do
              config cfg
            end
          end
        end
      end
      root_node
    end
    
    ##
    #
    def setup_project(proj)
      outer = self

      proj.attrs.instance_eval do
        vcglobal :ProjectName, name
        vcglobal :ProjectGuid, proj.guid
        vcglobal :RootNamespace, name
        vcglobal :WindowsTargetPlatformVersion, winsdkver
      end
      
      proj.configs.each do |cfg|
        cfg.attrs.instance_eval do
          vcproperty :CharacterSet, (unicode ? :Unicode : :NotSet), group: :pg1
          vcproperty :ConfigurationType, outer.configuration_type(type), group: :pg1
          vcproperty :PlatformToolset, toolset, group: :pg1
          vcproperty :UseDebugLibraries, debug, group: :pg1

          # ClCompile
          vcproperty :ExceptionHandling, outer.exception_handling(cfg.get_attr(:exceptions)), group: :ClCompile
          vcproperty :RuntimeTypeInfo, rtti, group: :ClCompile
        end
      end
    end
    
    ##
    #
    def configuration_type(type)
      case type
      when :app
        'Application'
      when :lib
        'StaticLibrary'
      when :dll
        'DynamicLibrary'
      else
        @services.jaba_error("'#{type}' unhandled")
      end
    end

    ##
    #
    def exception_handling(attr)
      if attr.value
        if attr.has_flag_option?(:structured)
          :Async
        else
          :Sync
        end
      else
        false
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
    
    ##
    # 
    def dump_jaba_output(g_root)
      @projects.each do |p|
        p_root = {}
        g_root[p.handle] = p_root
        p.dump_jaba_output(p_root)
      end
    end

  end
  
end
