require_relative 'common'

class JabaSrcCompiler

  def initialize
    @src_file_to_content = {}
    @single_ruby_string = ''
  end

  def compile
    make_single_ruby_file
  end

  def make_single_ruby_file
    src_files = Dir.glob("#{JABA.install_dir}/lib/**/*").select{|f| File.file?(f)}
    src_files.each do |sf|
      @src_file_to_content[sf] = IO.read(sf)
    end
    src_files.each do |sf|
      process_src_file(sf)
    end
  end

  def process_src_file(sf)
    str = @src_file_to_content[sf]
    str.scan(/require/) do
      
    end
  end

end

JabaSrcCompiler.new.compile