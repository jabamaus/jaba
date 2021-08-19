# frozen_string_literal: true

##
#
module JABA

  using JABACoreExt
  
  class Workspace

    attr_reader :services

    ##
    #
    def initialize(plugin, node, projects, configs)
      @plugin = plugin
      @services = @plugin.services
      @node = node
      @attrs = node.attrs
      @projects = projects
      @configs = configs
      @name = @attrs.name
      @workspacedir = @attrs.workspacedir
    end

    ##
    #
    def handle
      @node.handle
    end

  end

end
