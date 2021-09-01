require_relative 'common'
require 'rexml'

using JABACoreExt

class VxcprojSimplifier

  def run(dir:)
    @h = {}
    @outdir = "#{dir}_diffable"
    
    if File.exist?(@outdir)
      FileUtils.remove_dir(@outdir)
    end
    FileUtils.mkdir(@outdir)

    Dir.chdir(dir) do
      Dir.glob("*.vcxproj").each do |vcxproj|
        process_vcxproj(vcxproj)
      end
    end
  end

  def process_vcxproj(vcxproj)
    xml = IO.read(vcxproj)
    doc = REXML::Document.new(xml)
    doc.elements.each("Project/PropertyGroup") do |e|
      if e.attributes['Label'] == 'Globals'
        e.elements.each do |c|
          @h["Globals|#{c.name}"] = c.text
        end
      elsif e.attributes['Label'] == 'Configuration'
        e.elements.each do |c|
          @h["PG1|#{get_cfg(e)}|#{c.name}"] = c.text
        end
      elsif e.attributes['Label'] == 'UserMacros'
        # nothing
      else
        e.elements.each do |c|
          @h["PG2|#{get_cfg(e)}|#{c.name}"] = c.text
        end
      end
    end
    doc.elements.each("Project/ItemDefinitionGroup") do |e|
      cfg = get_cfg(e)
      e.elements.each do |group|
        group.elements.each do |prop|
          @h["#{group.name}|#{cfg}|#{prop.name}"] = prop.text
        end
      end
    end
    doc.elements.each("Project/ItemGroup") do |e|
      if e.attributes["Label"] == 'ProjectConfigurations'
        # nothing
      else
        e.elements.each do |c|
          @h["SRC|#{c.name}|#{c.attributes['Include']}"] = nil
        end
      end
    end

    @h = @h.sort.to_h
    final = ''
    @h.each do |k, v|
      final << if v
        "#{k} = #{v}"
      else
        k
      end
      final << "\n"
    end
    @h.clear
    
    outfile = "#{@outdir}/#{vcxproj}"

    puts "Writing #{outfile}"
    IO.write(outfile, final)
  end

  def get_cfg(elem)
    condition = elem.attributes['Condition']
    if condition !~ /'\$\(Configuration\)\|\$\(Platform\)'=='(.+)'/
      raise "Failed to extract configuration from #{condition}"
    end
    Regexp.last_match(1)
  end

end

VxcprojSimplifier.new.run(dir: "C:/projects/GitHub/ouroveon/build/_sln")
VxcprojSimplifier.new.run(dir: "C:/projects/GitHub/ouroveon/build/_sln2")

