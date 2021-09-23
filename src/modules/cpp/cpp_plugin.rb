##
#
class CppPlugin < JABA::Plugin
  
  attr_reader :projects

  ##
  #
  def init
    @all_project_nodes = []
    @host_to_project_nodes = {}
    @projects = []
    @project_ids = []
    @node_to_project = {}
    @export_only_dependencies_to_resolve = {}
    @valid_platforms = []
  end

  ##
  #
  def pre_process_definitions
    target_host_id = services.globals.target_host
    @target_host = services.node_from_handle(target_host_id.to_s) # TODO: move to services
    @supported_platforms = @target_host.attrs.cpp_supported_platforms

    platform_plugin = services.get_plugin(:platform)
    platform_plugin.services.root_nodes.each do |platform|
      platform.attrs.valid_archs.each do |arch|
        @valid_platforms << "#{platform}_#{arch}".to_sym
      end
    end
    @valid_platforms.sort!
  end

  ##
  #
  def process_definition
    definition = services.current_definition
    # If its an export only definition, ignore it as it should not get turned into a generatable project,
    # rather it is just there to export attributes. This definition will be processed later at dependency
    # resolution time.
    #
    if definition.has_flag?(:export_only)
      return :skip
    end

    @project_ids << definition.id

    root_node = services.make_node
    project_blocks = root_node.attrs.project
    config_blocks = root_node.attrs.config

    # Validate platform specification
    #
    target_platform_to_archs = {}
    root_node.attrs.platforms.each do |pspec|
      if !@valid_platforms.include?(pspec)
        JABA.error("Invalid platform spec '#{pspec.inspect_unquoted}'. Available: #{@valid_platforms}", errobj: root_node.get_attr(:platforms))
      end
      if pspec !~ /^(.*?)_(.*)/
        JABA.error("Cannot extract platform and architecture from '#{pspec}'")
      end
      platform = Regexp.last_match(1).to_sym
      arch = Regexp.last_match(2).to_sym
      if @supported_platforms.include?(platform)
        target_platform_to_archs.push_value(platform, arch)
      end
    end

    target_platform_to_archs.each do |tp, target_archs|
      pn = services.make_node(type_id: :cpp_project, name: tp, parent: root_node, blocks: project_blocks) do
        platform tp
      end

      @all_project_nodes << pn
      @host_to_project_nodes.push_value(@target_host, pn)

      pn.attrs.configs.each do |cfg|
        target_archs.each do |ta|
          services.make_node(type_id: :cpp_config, name: "#{ta}|#{cfg}", parent: pn, blocks: config_blocks) do
            config cfg
            arch ta
          end
        end
      end

      if pn.attrs.workspace
        defn_id = definition.id
        services.execute_jdl do
          workspace defn_id do
            projects defn_id
          end
        end
      end
    end
    root_node
  end

  ##
  #
  def custom_handle_array_reference(attr, ref_node_id)
    if attr.attr_def.defn_id == :deps
      dep_def = services.get_instance_definition("cpp|#{ref_node_id}", fail_if_not_found: false)
      if !dep_def
        JABA.error("'#{ref_node_id.inspect}' dependency not found")
      end
      if dep_def.has_flag?(:export_only)
        @export_only_dependencies_to_resolve.push_value(attr, dep_def)
        return true
      end
    end
    false
  end

  ##
  #
  def post_process_definitions
    return if @all_project_nodes.empty?
    
    @all_project_nodes.sort!{|x, y| x.handle.casecmp(y.handle)}
    @all_project_nodes.sort_topological! do |n, &b|
      n.attrs.deps.each(&b)
    end
    
    @all_project_nodes.reverse_each do |node|
      node.visit_attr(:deps) do |attr, value|
        dep_node = value
        soft = attr.has_flag_option?(:soft)
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
          process_node_exports(cfg, dep_cfg, is_config: true, soft_dependency: soft)
        end
      end
    end

    # Process dependencies on 'export only' cpp definitions, whose purpose is to export all their attributes but not to actually generate anything.
    # These dependencies are special because the export only definition is evaluated in the context of the cpp definition that depends on it.
    # This means that it will 'bind' to the platform and configs, and any other readable values of the depending definition.
    #
    # TODO: export only code needs much more explanation
    @export_only_dependencies_to_resolve.each do |attr, export_only_defs|
      export_only_defs.each do |export_only_def|
        # Get the project that depends on the export only module
        #
        project_node = attr.node

        # Create a temporary untracked node from the definition, parented to the project node which will mean that it will be able to
        # read its attributes (eg platform, config, host etc).
        # 
        services.push_definition(export_only_def) do
          export_only_root = services.make_node(
            name: 'export_only_root',
            flags: JABA::NodeFlags::NO_POST_CREATE | JABA::NodeFlags::NO_DEFAULTS | JABA::NodeFlags::NO_TRACK,
          )

          project_blocks = export_only_root.attrs.project
          config_blocks = export_only_root.attrs.config

          export_only_node = services.make_node(
            type_id: :cpp_project,
            name: 'project_export_only', 
            parent: project_node,
            flags: JABA::NodeFlags::NO_POST_CREATE | JABA::NodeFlags::NO_DEFAULTS | JABA::NodeFlags::NO_TRACK | JABA::NodeFlags::LAZY,
            blocks: project_blocks
          ) 
          export_only_node.set_parent(export_only_root)
          export_only_node.make_paths_absolute

          # Now merge the node's attributes into project node attrs
          #
          process_export_only_node_exports(project_node, export_only_node)

          project_node.children.each do |cfg_node|
            export_only_cfg_node = services.make_node(
              type_id: :cpp_config,
              name: 'config_export_only',
              parent: cfg_node,
              flags: JABA::NodeFlags::NO_POST_CREATE | JABA::NodeFlags::NO_DEFAULTS | JABA::NodeFlags::NO_TRACK | JABA::NodeFlags::LAZY,
              blocks: config_blocks
            )
            export_only_cfg_node.set_parent(export_only_node)
            export_only_cfg_node.make_paths_absolute

            # Now merge the node's attributes into its config node attrs
            #
            process_export_only_node_exports(cfg_node, export_only_cfg_node)
          end
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

    project_ids = @project_ids
    services.execute_jdl do
      workspace :all do
        projects project_ids
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
      JABA.error("#{node.describe} not found")
    end
    p
  end

  ##
  #
  def process_node_exports(target_node, dep_node, is_config: false, soft_dependency: false)
    dep_attrs = dep_node.attrs

    if is_config && !soft_dependency
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

          # Get the corresponding attr in this project node. This will always be a hash or an array.
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
  def process_export_only_node_exports(target_node, dep_node)
    dep_node.visit_attr(top_level: true) do |dep_attr|
      attr = nil

      # visit all attribute elements in array/hash
      #
      dep_attr.visit_attr do |elem|
        if !elem.attr_def.has_flag?(:exportable)
          services.jaba_warn("Ignoring #{elem.describe} as attribute definition not flagged with :exportable", errobj: elem)
        else
          # Get the corresponding attr in this project node. This will always be a hash or an array.
          #
          attr = target_node.get_attr(elem.defn_id) if !attr
          attr.insert_clone(elem)
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
  def build_output(root)
    @projects.each do |p|
      p_root = {}
      root[p.handle] = p_root
      p.build_output(p_root)
    end
  end

end
