# frozen_string_literal: true

##
#
module JABA

  using JABACoreExt

  ##
  #
  class WorkspaceGenerator < Generator
    
    Generator.work_with(:workspace)
    
    ##
    # For use by workspace generator. spec is either a defn_id or a wildcard match against projdir.
    # 
    def get_matching_projects(projects, root, specs, errobj:)
      specs.each do |spec|
        if spec.string? && spec.wildcard?
          abs_spec = "#{root}/#{spec}"
          matches = @candidate_projects.select do |p|
            File.fnmatch?(abs_spec, p.root)
           end
          if matches.empty?
            jaba_warn("No projects matching spec '#{spec.inspect_unquoted}' found", errobj: errobj)
          end
          projects.concat(matches)
        else # its an id
          matches = @candidate_projects.select do |p|
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
    def make_host_objects
      # TODO: pass this in
      cpp_gen = get_generator(:cpp)
      @candidate_projects = cpp_gen.get_projects
      @root_nodes.each do |wsn|
        services.globals.cpp_hosts.each do |target_host|
          classname = target_host.attrs.workspace_classname
          next if classname.empty?

          root = make_node_paths_absolute(wsn)

          projects = []
          projects_attr = wsn.get_attr(:projects)
          project_specs = projects_attr.value
          get_matching_projects(projects, root, project_specs, errobj: projects_attr)
    
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
    def generate
      each_workspace(&:generate)
    end
    
    ##
    # 
    def build_jaba_output(g_root, out_dir)
      @root_nodes.each do |w|
        w_root = {}
        g_root[w.handle] = w_root
        #p.build_jaba_output(p_root, out_dir)
      end
    end

  end
  
end
