# Generates a vscode launch.json for each example, unit test and tool

require_relative 'common'
require_relative '../examples/gen_all'

class LaunchJsonGenerator

  ##
  #
  def initialize
    @configs = []
  end
  
  ##
  #
  def generate
    vscode_dir = "#{JABA.install_dir}/.vscode"
    launch_json = "#{vscode_dir}/launch.json"
    root = {}
    root["version"] = "0.2.0"
    root['configurations'] = @configs

    separator 'examples'

    iterate_examples do |dirname|
      add_src_root("${workspaceRoot}/examples/#{dirname}", name: dirname, args: ['-D', 'target_host', 'vs2019'])
    end

    separator 'tests'

    Dir.glob("#{JABA.install_dir}/test/tests/**/test_*.rb").each do |t|
      testclass = t.basename_no_ext.split('_').collect(&:capitalize).join
      add_config(name: testclass, program: '${workspaceRoot}/test/test_jaba.rb', args: ['--', '--name', "/#{testclass}/"])
    end
    
    separator 'tools'

    Dir.glob("#{JABA.install_dir}/tools/*.rb").each do |t|
      tool = t.basename
      next if tool == 'common.rb'
      add_config(name: tool, program: "${workspaceRoot}/tools/#{tool}")
    end

    if !File.exist?(vscode_dir)
      FileUtils.mkdir(vscode_dir)
    end

    puts "Writing #{launch_json}"
    IO.write(launch_json, JSON.pretty_generate(root))
    puts 'Done!'
  end

  ##
  #
  def add_src_root(src_root, name:, args: nil)
    add_config(name: name,  program: '${workspaceRoot}/bin/jaba.rb', cwd: src_root, args: args)
  end

  ##
  #
  def separator(name)
    c = {}
    c['name'] = "------------- #{name} -------------"
    @configs << c
  end
  
private

  ##
  #
  def add_config(name:, program:, cwd: nil, args: nil)
    c = {}
    c['name'] = "Debug #{name}"
    c['type'] = 'Ruby'
    c['request'] = 'launch'
    c['program'] = program
    c['cwd'] = cwd if cwd
    c['args'] = Array(args)
    @configs << c
  end

end

lg = LaunchJsonGenerator.new

# TEMP
lg.add_src_root('C:/projects/GitHub/OUROVEON/build', name: 'OUROVEON',  args: ['-D', 'target_host', 'vs2019'])

lg.generate
