# frozen_string_literal: true

##
#
module JABA

  using JABACoreExt

  class Sln < Workspace

    ##
    #
    def init
      @name = @attrs.name
      @workspacedir = @attrs.workspacedir
      @sln_file = "#{@workspacedir}/#{@name}.sln"
    end

    ##
    #
    def generate
      services.log "Generating #{@sln_file}", section: true

      file = services.file_manager.new_file(@sln_file, eol: :windows, encoding: 'UTF-8', capacity: 32 * 1024)
      w = file.writer

      w << "Microsoft Visual Studio Solution File, Format Version 12.00" # TODO: soft code
      w << "# Visual Studio version 16.0.30114.105" # TODO: soft code

      w << 'Global'
      w << "\tGlobalSection(SolutionConfigurationPlatforms) = preSolution"
      w << "\tEndGlobalSection"
      w << "\tGlobalSection(ProjectConfigurationPlatforms) = postSolution"
      w << "\tEndGlobalSection"
      w << "\tGlobalSection(SolutionProperties) = preSolution"
      w << "\t\tHideSolutionNode = FALSE"
      w << "\tEndGlobalSection"
      w << 'EndGlobal'
      file.write
    end
    
  end

end
