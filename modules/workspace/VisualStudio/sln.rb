# frozen_string_literal: true

##
#
module JABA

  using JABACoreExt

  class Sln

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
      @sln_file = "#{@workspacedir}/#{@attrs.name}.sln"
    end

    ##
    #
    def handle
      @node.handle
    end

    ##
    #
    def generate
      services.log "Generating #{@sln_file}", section: true

      file = services.new_file(@sln_file, eol: :windows, encoding: 'UTF-8', capacity: 32 * 1024)
      w = file.writer

      w << "Microsoft Visual Studio Solution File, Format Version 12.00" # TODO: soft code
      w << "# Visual Studio version 16" # TODO: soft code

      @projects.each do |proj|
        path = proj.vcxproj_file.relative_path_from(@workspacedir, backslashes: true)
        w << "Project(\"{8BC9CEB8-8B4A-11D0-8D11-00A0C91BC942}\") = \"#{proj.projname}\", \"#{path}\", \"#{proj.guid}\""
        w << 'EndProject'
      end

      w << 'Global'
      
      w << "\tGlobalSection(SolutionConfigurationPlatforms) = preSolution"
      @configs.each do |cfg_info|
        w << "\t\t#{cfg_info[0]}|#{cfg_info[1]} = #{cfg_info[0]}|#{cfg_info[1]}"
      end
      w << "\tEndGlobalSection"
      
      w << "\tGlobalSection(ProjectConfigurationPlatforms) = postSolution"
      @projects.each do |proj|
        proj.each_config do |cfg|
          match = true
          proj_cfg = cfg.attrs.configname
          sln_cfg = proj_cfg # TODO
          proj_cfg_platform = cfg.attrs.arch_ref.attrs.vsname
          sln_cfg_platform = proj_cfg_platform # TODO: sln config platform could be different 
          w << "\t\t#{proj.guid}.#{sln_cfg}|#{sln_cfg_platform}.ActiveCfg = #{proj_cfg}|#{proj_cfg_platform}"
          if match
            w << "\t\t#{proj.guid}.#{sln_cfg}|#{sln_cfg_platform}.Build.0 = #{proj_cfg}|#{proj_cfg_platform}"
          end
        end
      end
      w << "\tEndGlobalSection"
      
      w << "\tGlobalSection(SolutionProperties) = preSolution"
      w << "\t\tHideSolutionNode = FALSE"
      w << "\tEndGlobalSection"
      
      w << 'EndGlobal'
      file.write
    end
    
  end

end
