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
    def make_nodes
      root_node = make_node(type_id: :cpp)
      
      combine = false

      # TODO: namespacing of sub type ids

      root_node.attrs.hosts.each do |h|
        host_node = make_node(type_id: :per_host, name: h, parent: root_node) do
          host h
          host_ref h
        end
        
        if combine
          @project_nodes << host_node
        end

        host_node.attrs.platforms.each do |p|
          platform_node = make_node(type_id: :per_platform, name: p, parent: host_node) do
            platform p
            platform_ref p
          end

          if !combine
            @project_nodes << platform_node
          end
          
          platform_node.attrs.configs.each do |cfg|
            make_node(type_id: :config, name: cfg, parent: platform_node) do
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
        vcglobal :ProjectName, projname
        vcglobal :ProjectGuid, proj.guid
        vcglobal :RootNamespace, projname
        vcglobal :WindowsTargetPlatformVersion, winsdkver
      end
      
      proj.each_config do |cfg|
        cfg.attrs.instance_eval do
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
          vcproperty :UseDebugLibraries, debug, group: :pg1
          vcproperty :CharacterSet, group: :pg1 do
            case character_set
            when :mbcs
              :MultiByte
            when :unicode
              :Unicode
            end
          end
          vcproperty :PlatformToolset, toolset, group: :pg1

          # ClCompile
          #
          vcproperty :AdditionalIncludeDirectories, group: :ClCompile do
            inc.vs_join_paths(inherit: '%(AdditionalIncludeDirectories)')
          end

          vcproperty :AdditionalOptions, group: :ClCompile do
            cflags.vs_join(separator: ' ', inherit: '%(AdditionalOptions)')
          end

          vcproperty :ExceptionHandling, group: :ClCompile do
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

          vcproperty :PreprocessorDefinitions, group: :ClCompile do
            defines.vs_join(inherit: '%(PreprocessorDefinitions)')
          end

          vcproperty :RuntimeTypeInfo, rtti, group: :ClCompile

          vcproperty :TreatWarningAsError, warnerror, group: :ClCompile

          # Link
          #
          vcproperty :TargetMachine, group: (type == :lib ? :Lib : :Link) do
            :MachineX64 if x64?
          end

          # Build events
          #
          cfg.visit_attr(:build_action) do |a, value|
            cmd = String.new
            msg = a.get_option_value(:msg, fail_if_not_found: false)
            cmd << "#{msg}\n" if msg
            cmd << value
            type = a.get_option_value(:type)
            group = case type
            when :PreBuild, :PreLink, :PostBuild
              "#{type}Event"
            end
            vcproperty :Command, cmd, group: group
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
      
      @project_nodes.reverse_each do |node|
        node.attrs.deps.each do |dep_node|
          dep_node.visit_attr(top_level: true) do |dep_attr|

            # Skip single value attributes as they cannot export. The reason for this is that exporting it would simply
            # overwrite the destination attribute creating a conflict. Which node should control the value? For this
            # reason disallow.
            #
            next if dep_attr.attr_def.variant == :single
            n_attr = nil

            # visit all attribute elements in array/hash
            #
            dep_attr.visit_attr do |elem|
              if elem.has_flag_option?(:export)

                # Get the corresponding attr in this project node. Only consider this node so don't set search: true.
                # This will always be a hash or an array.
                #
                n_attr = node.get_attr(elem.definition_id) if !n_attr
                n_attr.insert_clone(elem)
              end
            end
          end
        end
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
