# frozen_string_literal: true

##
#
module JABA

  using JABACoreExt

  ##
  #
  class CppPlugin < Plugin
    
    attr_reader :projects

    ##
    #
    def init
      @all_project_nodes = []
      @host_to_project_nodes = {}
      @projects = []
      @node_to_project = {}
    end

    ##
    #
    def process_definition(definition)
      platforms = definition.options[:platforms]

      target_platform_to_archs = {}
      platforms.each do |pspec|
        if pspec !~ /^(.*?)_(.*)/
          JABA.error("Cannot extract platform and architecture from '#{pspec}'")
        end
        platform = Regexp.last_match(1).to_sym
        arch = Regexp.last_match(2).to_sym
        target_platform_to_archs.push_value(platform, arch)
      end

      # TODO: tidy up by making node_from_handle better
      host_plugin = services.get_plugin(:host)

      services.globals.target_hosts.each do |target_host_id|
        target_host = host_plugin.services.node_from_handle(target_host_id.to_s)
        supported_platforms = target_host.attrs.cpp_supported_platforms

        target_platform_to_archs.each do |tp, target_archs|
          next if !supported_platforms.include?(tp)
          
          project_node = services.make_node(name: "#{target_host.defn_id}|#{tp}") do
            host target_host.defn_id
            host_ref target_host
            platform tp
            platform_ref tp
          end

          @all_project_nodes << project_node
          @host_to_project_nodes.push_value(target_host, project_node)

          project_node.attrs.configs.each do |cfg|
            target_archs.each do |ta|
              services.make_node(child_type_id: :cpp_config, name: "#{ta}|#{cfg}", parent: project_node) do
                config cfg
                arch ta
                arch_ref ta
              end
            end
          end

          if project_node.attrs.workspace
            defn_id = definition.id
            services.execute_jdl do
              workspace defn_id do
                projects defn_id
              end
            end
          end
        end
      end
      @all_project_nodes
    end

    ##
    #
    def make_host_objects
      services.execute_jdl do
        workspace :all do
          projects all_instance_ids(:cpp)
        end
      end
      
      @all_project_nodes.sort!{|x, y| x.handle.casecmp(y.handle)}
      @all_project_nodes.sort_topological! do |n, &b|
        n.attrs.deps.each(&b)
      end

      @all_project_nodes.each do |pn|
        services.make_node_paths_absolute(pn)
      end
      
      @all_project_nodes.reverse_each do |node|
        node.attrs.deps.each do |dep_node|
          process_node_exports(node, dep_node)
          dep_node.children.each do |dep_cfg|
            # TODO: This is pretty nasty. Improve.
            dep_cfg_handle = dep_cfg.handle[/^.*?\|(.*)/, 1]
            cfg = node.children.find do |c|
              c.handle[/^.*?\|(.*)/, 1] == dep_cfg_handle
            end
            if !cfg
              JABA.error("Could not find config in #{node.describe} to match #{dep_cfg.describe}")
            end
            process_node_exports(cfg, dep_cfg)
          end
        end
      end

      @host_to_project_nodes.each do |host, project_nodes|
        if host.defn_id == :ninja
        else
          classname = host.attrs.cpp_project_classname
          project_nodes.each do |pn|
            make_project(classname, pn)
          end
        end
      end
    end

    ##
    #
    def make_project(classname, node, *args, **keyval_args)
      klass = JABA.const_get(classname)
      project = klass.new(self, node, *args, **keyval_args)
      @projects << project
      @node_to_project[node] = project
      project.post_create
    end

    ##
    #
    def project_from_node(node, fail_if_not_found: true)
      p = @node_to_project[node]
      if !p && fail_if_not_found
        JABA.error("'#{node.describe}' not found")
      end
      p
    end

    ##
    #
    def process_node_exports(target_node, dep_node)
      dep_attrs = dep_node.attrs

      case dep_attrs.type
      when :lib
        if target_node.attrs.type != :lib
          target_node.attrs.libs ["#{dep_attrs.libdir}/#{dep_attrs.targetname}#{dep_attrs.targetext}"]
        end
      when :dll
        if target_node.attrs.type != :lib
          il = dep_attrs.importlib
          if il # dlls don't always have import libs - eg plugins
            target_node.attrs.libs ["#{dep_attrs.libdir}/#{il}"]
          end
        end
      end

      # Skip single value attributes as they cannot export. The reason for this is that exporting it would simply
      # overwrite the destination attribute creating a conflict. Which node should control the value? For this
      # reason disallow.
      #
      dep_node.visit_attr(top_level: true, skip_variant: :single) do |dep_attr|
        attr = nil

        # visit all attribute elements in array/hash
        #
        dep_attr.visit_attr do |elem|
          export_only = elem.has_flag_option?(:export_only)
          if elem.has_flag_option?(:export) || export_only

            # Get the corresponding attr in this project node. Only consider this node so don't set search: true.
            # This will always be a hash or an array.
            #
            attr = target_node.get_attr(elem.defn_id) if !attr
            attr.insert_clone(elem)

            # Exported items are deleted from the exporting module if :export_only specified
            #
            :delete if export_only
          end
        end
      end
    end

    ##
    #
    def generate
      @projects.each do |p|
        p.generate
      end
    end
    
    ##
    # 
    def build_jaba_output(root, out_dir)
      @projects.each do |p|
        p_root = {}
        root[p.handle] = p_root
        p.build_jaba_output(p_root, out_dir)
      end
    end

  end
  
end