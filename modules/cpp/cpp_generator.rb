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
    end

    ##
    #
    def make_nodes
      root_node = make_node

      root_node.attrs.hosts.each do |h|
        host_node = make_node(sub_type_id: :per_host, name: h, parent: root_node) do
          host h
          host_ref h
        end
        
        host_node.attrs.platforms.each do |p|
          platform_node = make_node(sub_type_id: :project, name: p, parent: host_node) do
            platform p
            platform_ref p
          end

          @platform_nodes << platform_node

          platform_node.attrs.archs.each do |a|
            arch_node = make_node(sub_type_id: :per_arch, name: a, parent: platform_node) do
              arch a
              arch_ref a
            end
          
            arch_node.attrs.configs.each do |cfg|
              make_node(sub_type_id: :config, name: cfg, parent: arch_node) do
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
                attr = node.get_attr(elem.defn_id) if !attr
                attr.insert_clone(elem)
              end
            end
          end
        end
      end

      @platform_nodes.each do |pn|
        # Turn root into absolute path
        #
        root = pn.get_attr(:root, search: true).map_value! do |r|
          r.absolute_path? ? r : "#{pn.definition.source_dir}/#{r}".cleanpath
        end

        # Make all file/dir/path attributes into absolute paths based on root
        #
        pn.visit_node(visit_self: true) do |node|
          node.visit_attr(type: [:file, :dir], skip_attr: :root) do |a|
            a.map_value! do |p|
              p.absolute_path? ? p : "#{root}/#{p}".cleanpath
            end
          end
        end

        klass = pn.attrs.host_ref.attrs.cpp_project_classname
        proj = make_project(klass, pn, root)
        proj.process_src(:src, :src_ext)
      end
    end

    ##
    #
    def generate
      @projects.each(&:generate)
    end
    
    ##
    # 
    def build_jaba_output(g_root, out_dir)
      @projects.each do |p|
        p_root = {}
        g_root[p.handle] = p_root
        p.build_jaba_output(p_root, out_dir)
      end
    end

  end
  
end
