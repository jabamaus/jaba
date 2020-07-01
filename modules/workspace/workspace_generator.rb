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
    #
    def init
      @workspace_nodes = []
    end

    ##
    #
    def make_nodes
      root_node = make_node
      @workspace_nodes << root_node

      @root = make_node_paths_absolute(root_node)

      # TODO: pass this in
      cpp_gen = get_generator(:cpp)
      
      @candidate_projects = cpp_gen.get_projects
      @projects = []

      projects_attr = root_node.get_attr(:projects)
      project_specs = projects_attr.value
      get_matching_projects(project_specs, callstack: projects_attr.last_call_location)

      if @projects.empty?
        jaba_error("No projects matched specs", callstack: projects_attr.last_call_location)
      end

      @configs = {}
      @projects.each do |p|
        p.each_config do |cfg|
          cfg_id = cfg.attrs.config
          if !@configs.key?(cfg_id)
            @configs[cfg_id] = [cfg.attrs.configname, cfg.attrs.arch_ref.attrs.vsname]
          end
        end
      end
      @configs = @configs.values

      root_node
    end
    
    ##
    # For use by workspace generator. spec is either a defn_id or a wildcard match against projdir.
    # 
    def get_matching_projects(specs, callstack:)
      specs.each do |spec|
        if spec.string? && spec.wildcard?
          abs_spec = "#{@root}/#{spec}"
          matches = @candidate_projects.select{|p| File.fnmatch?(abs_spec, p.projdir)}
          if matches.empty?
            jaba_warning("No projects matching spec '#{spec.inspect_unquoted}' found", callstack: callstack)
          end
          @projects.concat(matches)
        else # its an id
          matches = @candidate_projects.select{|p| p.handle.start_with?("#{spec}|")}
          if matches.empty?
            jaba_error("No projects matching spec '#{spec.inspect_unquoted}' found", callstack: callstack)
          end
          @projects.concat(matches)
        end
      end
    end

    ##
    #
    def make_host_objects
      @workspace_nodes.each do |wsn|
        #klass = wsn.attrs.host_ref.attrs.workspace_classname
        make_workspace('Sln', wsn, @projects, @configs)
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
      @workspace_nodes.each do |w|
        w_root = {}
        g_root[w.handle] = w_root
        #p.build_jaba_output(p_root, out_dir)
      end
    end

  end
  
end
