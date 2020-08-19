# frozen_string_literal: true

##
#
module JABA

  using JABACoreExt
  
  class Workspace < Project

    ##
    #
    def initialize(generator, node, projects, configs)
      super(generator, node)
      @projects = projects
      @configs = configs
      @name = @attrs.name
      @workspacedir = @attrs.workspacedir
    end

  end

end
