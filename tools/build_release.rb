require 'FileUtils'

class ReleaseBuilder

  def initialize
    @src_root = "#{__dir__}/.."
    @dest_root = "#{__dir__}/release_temp/jaba"
    @files = []
  end

  def add(spec, exclude: nil)
    Dir.chdir(@src_root) do
      files = Dir.glob(spec)
      files.select!{|f| !File.directory?(f)}
      excluded = []
      if exclude
        Array(exclude).each do |e|
          excluded.concat(Dir.glob(e))
        end
      end
      excluded.each do |e|
        puts "excluding #{e}"
        files.delete(e)
      end
      @files.concat(files)
    end
  end

  def build
    FileUtils.remove_dir(@dest_root) if File.exist?(@dest_root)
    FileUtils.makedirs(@dest_root)

    dest_dirs_to_create = []

    @files.each do |f|
      dest_dir = "#{@dest_root}/#{File.dirname(f)}"
      dest_dirs_to_create << dest_dir if !dest_dirs_to_create.include?(dest_dir)
    end

    dest_dirs_to_create.each do |dir|
      puts "making #{dir}"
      FileUtils.makedirs(dir)
    end

    @files.each do |f|
      s = "#{@src_root}/#{f}"
      d = "#{@dest_root}/#{f}"
      puts "Copying #{s} to #{d}"
      FileUtils.copy_file(s, d)
    end
  end

end

b = ReleaseBuilder.new
b.add('bin/jaba.bat')
b.add('bin/jaba.rb')
b.add('bin/jabaruby.exe')
b.add('examples/**/*', exclude: 'examples/projects/**/*')
b.add('lib/**/*')
b.add('modules/**/*')
b.add('LICENSE')
b.add('README.md') # TODO: turn README into html

b.build

# TODO: Check working copy has no changes
# TODO: clean working copy
# TODO: link to versioned docs
# TODO: copy docs to docs branch, build and publish