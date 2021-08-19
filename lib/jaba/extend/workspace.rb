# frozen_string_literal: true

##
#
module JABA

  using JABACoreExt
  
  class Workspace < Project

    ##
    #
    def initialize(plugin, node, projects, configs)
      super(plugin, node)
      @projects = projects
      @configs = configs
      @name = @attrs.name
      @workspacedir = @attrs.workspacedir
    end

  end

end
