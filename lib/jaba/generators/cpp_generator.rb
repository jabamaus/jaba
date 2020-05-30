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
      @platform_nodes = []
      @projects = []
    end

    ##
    #
    def make_nodes
      root_node = make_node(type_id: :cpp)

      # TODO: namespacing of sub type ids

      root_node.attrs.hosts.each do |h|
        host_node = make_node(type_id: :per_host, name: h, parent: root_node) do
          host h
          host_ref h
        end
        
        host_node.attrs.platforms.each do |p|
          platform_node = make_node(type_id: :per_platform, name: p, parent: host_node) do
            platform p
            platform_ref p
          end

          @platform_nodes << platform_node

          platform_node.attrs.archs.each do |a|
            arch_node = make_node(type_id: :per_arch, name: a, parent: platform_node) do
              arch a
              arch_ref a
            end
          
            arch_node.attrs.configs.each do |cfg|
              make_node(type_id: :config, name: cfg, parent: arch_node) do
                config cfg
              end
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
          cfg_type = type
          vcproperty :ConfigurationType, group: :pg1 do
            case cfg_type
            when :app, :console
              'Application'
            when :lib
              'StaticLibrary'
            when :dll
              'DynamicLibrary'
            else
              fail "'#{cfg_type}' unhandled"
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
          if cfg_type != :lib
            vcproperty :SubSystem, group: :Link do
              case cfg_type
              when :console
                :Console
              when :app, :dll
                :Windows
              else
                raise "'#{type}' unhandled"
              end
            end
          end

          vcproperty :TargetMachine, group: (cfg_type == :lib ? :Lib : :Link) do
            :MachineX64 if x86_64?
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
      @platform_nodes.sort_topological! do |n, &b|
        n.attrs.deps.each(&b)
      end
      
      @platform_nodes.reverse_each do |node|
        node.attrs.deps.each do |dep_node|
          # Skip single value attributes as they cannot export. The reason for this is that exporting it would simply
          # overwrite the destination attribute creating a conflict. Which node should control the value? For this
          # reason disallow.
          #
          dep_node.visit_attr(top_level: true, skip_variant: :single) do |dep_attr|
            attr = nil

            # visit all attribute elements in array/hash
            #
            dep_attr.visit_attr do |elem|
              if elem.has_flag_option?(:export)

                # Get the corresponding attr in this project node. Only consider this node so don't set search: true.
                # This will always be a hash or an array.
                #
                attr = node.get_attr(elem.definition_id) if !attr
                attr.insert_clone(elem)
              end
            end
          end
        end
      end

      @platform_nodes.each do |pn|
        proj = make_project(Vcxproj, pn)
        proj.process_src(:src, :src_ext)
        @projects << proj
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
