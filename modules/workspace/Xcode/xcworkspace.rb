# frozen_string_literal: true

module JABA

  ##
  #
  class Xcworkspace

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
      @workspacedir = @attrs.workspacedir
      @sln_file = "#{@workspacedir}/#{@attrs.name}.xcworkspace"
    end

    ##
    #
    def handle
      @node.handle
    end

    ##
    #
    def generate
    end

  end

end
