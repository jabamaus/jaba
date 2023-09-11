module JABA
  class Sln
    def initialize(node, projects)
      @workspacedir = node[:dir]
      @sln_file = "#{@workspacedir}/#{node[:name]}.sln"
      @projects = projects
    end

    def generate
      file = JABA.context.file_manager.new_file(@sln_file, eol: :windows, encoding: 'UTF-8')
      w = file.writer

      w << "Microsoft Visual Studio Solution File, Format Version 12.00" # TODO: soft code
      w << "# Visual Studio version 17" # TODO: soft code

      sln_configs = {}
      @projects.each do |p|
        path = p.vcxproj_file.relative_path_from(@workspacedir, backslashes: true)
        w << "Project(\"{8BC9CEB8-8B4A-11D0-8D11-00A0C91BC942}\") = \"#{p.projname}\", \"#{path}\", \"#{p.guid}\""
        w << 'EndProject'
        p.node.each_config do |cfg|
          name = cfg[:configname]
          if !sln_configs.has_key?(name)
            sln_configs[name] = "x64" # TODO
          end
        end
      end

      w << "Global"
      w << "\tGlobalSection(SolutionConfigurationPlatforms) = preSolution"
      sln_configs.each do |name, platform|
        w << "\t\t#{name}|#{platform} = #{name}|#{platform}"
      end
      w << "\tEndGlobalSection"

      w << "\tGlobalSection(ProjectConfigurationPlatforms) = postSolution"
      @projects.each do |p|
        p.node.each_config do |cfg|
          match = true
          proj_cfg = cfg[:configname]
          sln_cfg = proj_cfg # TODO
          proj_cfg_platform = "x64" # TODO
          sln_cfg_platform = proj_cfg_platform # TODO: sln config platform could be different 
          w << "\t\t#{p.guid}.#{sln_cfg}|#{sln_cfg_platform}.ActiveCfg = #{proj_cfg}|#{proj_cfg_platform}"
          if match
            w << "\t\t#{p.guid}.#{sln_cfg}|#{sln_cfg_platform}.Build.0 = #{proj_cfg}|#{proj_cfg_platform}"
          end
        end
      end
      w << "\tEndGlobalSection"
      
      w << "\tGlobalSection(SolutionProperties) = preSolution"
      w << "\t\tHideSolutionNode = FALSE"
      w << "\tEndGlobalSection"
      
      w << "EndGlobal"
      file.write
    end
  end
end