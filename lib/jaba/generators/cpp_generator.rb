# frozen_string_literal: true

##
#
module JABA

  using JABACoreExt

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
      when :platform, :platform_ref, :hosts
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
          platform_ref p
        end
        
        hosts_node.attrs.hosts.each do |h|
          proj_node = make_node(type_id: :cpp, name: h, parent: hosts_node) do
            host h
            host_ref h
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

      proj.attrs.instance_eval do
        vcglobal :ProjectName, name
        vcglobal :ProjectGuid, proj.guid
        vcglobal :RootNamespace, name
        vcglobal :WindowsTargetPlatformVersion, winsdkver
      end
      
      proj.configs.each do |cfg|
        cfg.attrs.instance_eval do
          vcproperty :CharacterSet, (unicode ? :Unicode : :NotSet), group: :pg1
          vcproperty :ConfigurationType, group: :pg1 do
            case type
            when :app
              'Application'
            when :lib
              'StaticLibrary'
            when :dll
              'DynamicLibrary'
            else
              fail "'#{type}' unhandled"
            end
          end
          vcproperty :PlatformToolset, toolset, group: :pg1
          vcproperty :UseDebugLibraries, debug, group: :pg1

          # ClCompile
          #
          vcproperty :AdditionalIncludeDirectories, idg: :ClCompile do
            inc.vs_join_paths(inherit: '%(AdditionalIncludeDirectories)')
          end

          vcproperty :AdditionalOptions, idg: :ClCompile do
            cflags.vs_join(separator: ' ', inherit: '%(AdditionalOptions)')
          end

          vcproperty :ExceptionHandling, idg: :ClCompile do
            case exceptions
            when true
              :Sync
            when false
              false
            when :structured
              :Async
            else
              fail "'#{exceptions}' unhandled"
            end
          end

          vcproperty :PreprocessorDefinitions, idg: :ClCompile do
            defines.vs_join(inherit: '%(PreprocessorDefinitions)')
          end

          vcproperty :RuntimeTypeInfo, rtti, idg: :ClCompile

          vcproperty :TreatWarningAsError, warnerror, idg: :ClCompile

          # Link
          #
          vcproperty :TargetMachine, idg: (type == :lib ? :Lib : :Link) do
            :MachineX64 if x64?
          end
        end
      end
    end

    ##
    #
    def make_projects
      @project_nodes.sort_topological! do |n, &b|
        n.attrs.deps.each(&b)
      end
      
      @project_nodes.each do |pn|
        @projects << make_project(Vcxproj, pn)
      end
    end

    ##
    #
    def generate
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
