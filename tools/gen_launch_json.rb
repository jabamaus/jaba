# Generates a vscode launch.json for each example, unit test and tool

require_relative 'common'
require_relative '../examples/gen_all'

using JABACoreExt

class LaunchJsonGenerator

  def generate
    vscode_dir = "#{JABA.install_dir}/.vscode"
    launch_json = "#{vscode_dir}/launch.json"
    root = {}
    root["version"] = "0.2.0"

    @configs = []
    root['configurations'] = @configs

    iterate_examples do |dirname|
      add_config(name: dirname, program: '${workspaceRoot}/bin/jaba.rb', cwd: "${workspaceRoot}/examples/#{dirname}")
    end

    Dir.glob("#{JABA.install_dir}/test/tests/test_*.rb").each do |t|
      testclass = t.basename_no_ext.split('_').collect(&:capitalize).join
      add_config(name: testclass, program: '${workspaceRoot}/test/test_jaba.rb', args: ['--', '--name', "/#{testclass}/"])
    end
    
    Dir.glob("#{JABA.install_dir}/tools/*.rb").each do |t|
      tool = t.basename
      next if tool == 'common.rb'
      add_config(name: tool, program: "${workspaceRoot}/tools/#{tool}")
    end

    if !File.exist?(vscode_dir)
      FileUtils.mkdir(vscode_dir)
    end

    IO.write(launch_json, JSON.pretty_generate(root))
  end

  def add_config(name:, program:, cwd: nil, args: nil)
    c = {}
    c['name'] = "Debug #{name}"
    c['type'] = 'Ruby'
    c['request'] = 'launch'
    c['program'] = program
    c['cwd'] = cwd if cwd
    c['args'] = Array(args) if args
    @configs << c
  end

end

LaunchJsonGenerator.new.generate
