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
      @workspaces << root_node

      cpp_generator = get_generator(:cpp)
      
      # Build a union of all hosts and platforms of the specified project
      #
      all_hosts = []
      all_platforms = []
      root_node.attrs.projects.each do |proj_spec|
        if proj_spec.symbol?

        elsif proj_spec.wildcard?

        else
        end
      end
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
