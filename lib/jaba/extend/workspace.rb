# frozen_string_literal: true

##
#
module JABA

  using JABACoreExt
  
  class Workspace < Project

    ##
    #
    def init(projects, configs)
      @projects = projects
      @configs = configs
      @name = @attrs.name
      @workspacedir = @attrs.workspacedir
    end
    
  end

end
