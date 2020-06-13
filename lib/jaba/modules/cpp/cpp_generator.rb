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
      root_node = make_node

      root_node.attrs.hosts.each do |h|
        host_node = make_node(sub_type_id: :per_host, name: h, parent: root_node) do
          host h
          host_ref h
        end
        
        host_node.attrs.platforms.each do |p|
          platform_node = make_node(sub_type_id: :per_platform, name: p, parent: host_node) do
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
    # TODO: make this fully generic
    def setup_project(proj)
      return if !proj.attrs.visual_studio?

      t = @services.get_translator(:vcxproj_windows)
      t.execute(node: proj.node, args: [proj])
      
      proj.each_config do |cfg|
        t = @services.get_translator(:vcxproj_config_windows)
        t.execute(node: cfg, args: [proj, cfg.attrs.type], &t.definition.block)

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

        # TODO: make pluggable
        klass = if pn.attrs.visual_studio?
          Vcxproj
        elsif pn.attrs.xcode?
          XcodeProj
        else
          raise 'unknown host'
        end
        proj = make_project(klass, pn, root)
        proj.process_src(:src, :src_ext)
        @projects << proj
      end
    end

    ##
    # For use by workspace generator. spec is either a defn_id or a wildcard match against projroot.
    # 
    def get_matching_projects(spec)
      defn_id = spec.symbol? ? spec : nil
      wildcard = spec.wildcard?

      matches = @projects.select do |proj|
        if defn_id && proj.handle.start_with?("#{spec}|")
          true
        elsif wildcard && File.fnmatch?(wildcard, proj.root)
          true
        end
      end
      if matches.empty?
        jaba_warning("'#{spec.inspect_unquoted}' did not match any projects")
      end
      matches
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
