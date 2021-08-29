# frozen_string_literal: true

##
#
module JABA

  using JABACoreExt
    
  ##
  #
  class WorkspacePlugin < Plugin

    ##
    #
    def init
      @workspaces = []
    end

    ##
    # 
    def get_matching_projects(candidate_projects, projects, root, specs, errobj:)
      specs.each do |spec|
        if spec.string? && spec.wildcard?
          abs_spec = "#{root}/#{spec}"
          matches = candidate_projects.select do |p|
            File.fnmatch?(abs_spec, p.root)
           end
          if matches.empty?
            services.jaba_warn("No projects matching spec '#{spec.inspect_unquoted}' found", errobj: errobj)
          end
          projects.concat(matches)
        else # its an id
          matches = candidate_projects.select do |p|
            p.handle.start_with?("#{spec}|")
          end
          if matches.empty?
            JABA.error("No projects matching spec '#{spec.inspect_unquoted}' found", errobj: errobj)
          end
          projects.concat(matches)
        end
      end
    end

    ##
    #
    def process_definition(definition)
      services.make_node
    end

    ##
    #
    def make_host_objects
      # TODO: pass this in
      cpp_plugin = services.get_plugin(:cpp)
      services.globals.target_hosts.each do |target_host_id|
        target_host = services.node_from_handle(target_host_id.to_s)
        classname = target_host.attrs.workspace_classname
        next if classname.empty?
        candidate_projects = cpp_plugin.projects.select{|p| p.attrs.host == target_host_id}

        services.root_nodes.each do |wsn|
          root = services.make_node_paths_absolute(wsn)

          projects = []
          projects_attr = wsn.get_attr(:projects)
          project_specs = projects_attr.value
          get_matching_projects(candidate_projects, projects, root, project_specs, errobj: projects_attr)
    
          if projects.empty?
            JABA.error("No projects matched specs", errobj: projects_attr)
          end
    
          configs = {}
          projects.each do |p|
            p.each_config do |cfg|
              cfg_id = cfg.handle[/^.*?\|(.*)/, 1] # TODO: nasty
              if !configs.key?(cfg_id)
                configs[cfg_id] = [cfg.attrs.configname, cfg.attrs.arch_ref.attrs.vsname]
              end
            end
          end
          configs = configs.values
          make_workspace(classname, wsn, projects, configs)
        end
      end
    end

    ##
    #
    def make_workspace(classname, node, *args, **keyval_args)
      klass = JABA.const_get(classname)
      ws = klass.new(self, node, *args, **keyval_args)
      @workspaces << ws
    end

    ##
    #
    def generate
      @workspaces.each do |w|
        w.generate
      end
    end
    
    ##
    # 
    def build_jaba_output(root, out_dir)
      @workspaces.each do |w|
        w_root = {}
        root[w.handle] = w_root
        #p.build_jaba_output(p_root, out_dir)
      end
    end

  end
  
end
