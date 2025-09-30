module JABA
  class Sln
    def initialize(node, projects)
      @workspacedir = node[:dir]
      @sln_file = "#{@workspacedir}/#{node[:name]}.slnx"
      @projects = projects
    end

    def generate
      file = JABA.context.file_manager.new_file(@sln_file, eol: :windows, encoding: 'UTF-8')
      w = file.writer

      w << "<Solution>"
      w << "  <Configurations>"
      w << "    <Platform Name=\"x64\" />" # TODO: soft code
      w << "  </Configurations>"

      @projects.each do |p|
        path = p.vcxproj_file.relative_path_from(@workspacedir, backslashes: true)
        w << "  <Project Path=\"#{path}\" Id=\"#{p.guid}\" />"
      end

      w << "</Solution>"
      file.write
    end
  end
end