# frozen_string_literal: true

##
#
module JABA

  using JABACoreExt

  ##
  #
  class WorkspaceGenerator < Generator
    
    ##
    #
    def init
      @workspaces = []
      @workspace_nodes = []
    end

    ##
    #
    def make_nodes
      root_node = make_node
      @workspace_nodes << root_node

      @root = root_node.get_attr(:root).map_value! do |r|
        r.absolute_path? ? r : "#{root_node.definition.source_dir}/#{r}".cleanpath
      end

      # TODO: pass this in
      cpp_gen = get_generator(:cpp)
      
      @candidate_projects = cpp_gen.get_projects
      @projects = []

      project_specs = root_node.attrs.projects
      get_matching_projects(project_specs)

      if @projects.empty?
        jaba_error("No matching projects")
      end

      all_hosts = {}
      all_platforms = {}

      @projects.each do |p|
        host = p.host
        platform = p.platform
        if !all_hosts.key?(host)
          all_hosts[host] = nil
        end
        if !all_platforms.key?(platform)
          all_platforms[platform] = nil
        end
      end

      all_hosts = all_hosts.keys
      all_platforms = all_platforms.keys

      root_node
    end
    
    ##
    # For use by workspace generator. spec is either a defn_id or a wildcard match against projroot.
    # 
    def get_matching_projects(specs)
      specs.each do |spec|
        if spec.string? && spec.wildcard?
          abs_spec = "#{@root}/#{spec}"
          matches = @candidate_projects.select{|p| File.fnmatch?(abs_spec, p.projroot)}
          if matches.empty?
            jaba_warning("Could not find any projects matching spec '#{spec.inspect_unquoted}'")
          end
          @projects.concat(matches)
        else # its an id
          matches = @candidate_projects.select{|p| p.handle.start_with?("#{spec}|")}
          if matches.empty?
            jaba_error("Could not find any projects matching spec '#{spec.inspect_unquoted}'")
          end
          @projects.concat(matches)
        end
      end
    end

    ##
    #
    def make_projects
    end

    ##
    #
    def generate
      #@workspaces.each(&:generate)
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
