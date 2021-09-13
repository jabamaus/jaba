require_relative 'common'

class ReleaseBuilder

  include CommonUtils

  def initialize
    @release_temp = "#{__dir__}/release_temp"
    @src_root = "#{@release_temp}/clean"
    @dest_root = "#{@release_temp}/jaba"
    @files = []
  end

  def init
    FileUtils.remove_dir(@release_temp) if File.exist?(@release_temp)
    FileUtils.makedirs(@release_temp)

    system("git clone --branch master --single-branch #{JABA_REPO_URL} #{@src_root}")
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
    dest_dirs_to_create = []

    @files.each do |f|
      dest_dir = "#{@dest_root}/#{f.parent_path}"
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
b.init
b.add('bin/jaba.bat')
b.add('bin/jaba.rb')
b.add('bin/jabaruby.exe')
b.add('examples/**/*', exclude: 'examples/**/buildsystem/**/*')
b.add('grab_bag/**/*')
b.add('src/**/*')
b.add('modules/**/*')
b.add('LICENSE')
b.add('README.md') # TODO: turn README into html
b.build

# TODO: link to versioned docs
# TODO: copy docs to docs branch, build and publish
# TODO: check for accidentally checked in .jaba dirs in release
