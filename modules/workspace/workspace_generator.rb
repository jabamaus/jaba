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
    end

    ##
    #
    def make_nodes
      root_node = make_node
=begin
      @workspaces << root_node

      cpp_gen = get_generator(:cpp)
      
      # Build a union of all hosts and platforms of the specified project
      #
      all_hosts = {}
      all_platforms = {}
      all_projects = []

      root_node.attrs.projects.each do |proj_spec|
        all_projects.concat(cpp_gen.get_matching_projects(proj_spec))
      end

      if all_projects.empty?
        jaba_error("No matching projects")
      end

      all_projects.each do |p|
        host = p.host
        platform = p.platform
        if !all_hosts.key?(host)
          all_hosts[host] = nil
        end
        if !all_platforms.key?(platform)
          all_platforms[platform] = nil
        end
      end
=end
      root_node
    end
    
    ##
    #
    def make_projects
    end

    ##
    #
    def generate
      @workspaces.each(&:generate)
    end
    
    ##
    # 
    def build_jaba_output(g_root, out_dir)
      @workspaces.each do |w|
        w_root = {}
        g_root[p.handle] = w_root
        #p.build_jaba_output(p_root, out_dir)
      end
    end

  end
  
end
