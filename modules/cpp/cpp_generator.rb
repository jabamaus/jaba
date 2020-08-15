# frozen_string_literal: true

##
#
module JABA

  using JABACoreExt

  ##
  #
  class CppGenerator < Generator
    
    Generator.work_with(:project)
     
    ##
    #
    def init
      @project_nodes = []
    end

    ##
    #
    def make_nodes
      root_node = make_node

      target_platform_to_archs = {}
      root_node.attrs.platforms.each do |pspec|
        if pspec !~ /^(.*?)_(.*)/
          JABA.error("Cannot extract platform and architecture from '#{pspec}'")
        end
        platform = Regexp.last_match(1).to_sym
        arch = Regexp.last_match(2).to_sym
        target_platform_to_archs.push_value(platform, arch)
      end

      services.globals.cpp_hosts.each do |target_host|
        supported_platforms = target_host.attrs.cpp_supported_platforms
        target_platform_to_archs.each do |target_platform, target_archs|
          next if !supported_platforms.include?(target_platform)
          project_node = make_node(sub_type_id: :project, name: "#{target_host.defn_id}|#{target_platform}", parent: root_node) do
            host target_host.defn_id
            host_ref target_host
            platform target_platform
            platform_ref target_platform
          end

          @project_nodes << project_node

          project_node.attrs.configs.each do |cfg|
            target_archs.each do |target_arch|
              make_node(sub_type_id: :config, name: "#{target_arch}|#{cfg}", parent: project_node) do
                config cfg
                arch target_arch
                arch_ref target_arch
              end
            end
          end
        end
      end
      root_node
    end

    ##
    #
    def make_host_objects
      @project_nodes.sort!{|x, y| x.handle.casecmp(y.handle)}
      @project_nodes.sort_topological! do |n, &b|
        n.attrs.deps.each(&b)
      end

      @project_nodes.each do |pn|
        make_node_paths_absolute(pn)
      end
      
      @project_nodes.reverse_each do |node|
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

      @project_nodes.each do |pn|
        klass = pn.attrs.host_ref.attrs.cpp_project_classname
        proj = make_project(klass, pn)
        proj.process_src(:src, :src_ext)
      end
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
          if elem.has_flag_option?(:export)

            # Get the corresponding attr in this project node. Only consider this node so don't set search: true.
            # This will always be a hash or an array.
            #
            attr = target_node.get_attr(elem.defn_id) if !attr
            attr.insert_clone(elem)

            # Exported items are deleted from the exporting module by default, unless :no_delete specified
            #
            :delete if !elem.has_flag_option?(:no_delete)
          end
        end
      end
    end

    ##
    #
    def generate
      each_project(&:generate)
    end
    
    ##
    # 
    def build_jaba_output(g_root, out_dir)
      each_project do |p|
        p_root = {}
        g_root[p.handle] = p_root
        p.build_jaba_output(p_root, out_dir)
      end
    end

  end
  
end
