require_relative 'common'
require 'rexml'

using JABACoreExt

class JabaTypeBuilder

  ##
  #
  def to_jaba_type(xml_file)
    if !File.exist?(xml_file)
      raise "#{xml_file} does not exist"
    end
    @attrs = []
    doc = REXML::Document.new(IO.read(xml_file))
    rule_elem = doc.elements['ProjectSchemaDefinitions/Rule']

    @name = rule_elem.attributes['Name'].downcase
    @display_name = rule_elem.attributes['DisplayName']

    rule_elem.elements.each do |e|
      # Skip if property has a data source child elem, eg StringListProperty.DataSource
      #
      next if e.elements["#{e.name}.DataSource"]
      
      case e.name
      when 'BoolProperty'
        add_attr(e, :bool)
      when 'StringProperty'
        add_attr(e, :string)
      when 'StringListProperty'
        add_attr(e, :string, array: true)
      when 'IntProperty'
        add_attr(e, :int)
      when 'EnumProperty'
        add_attr(e, :choice)
      when 'Rule.DataSource', 'Rule.Categories', 'DynamicEnumProperty'
        # nothing
      else
        raise "Unrecognised <Rule> child '#{e.name}'"
      end
    end

    @attrs.sort_by!{|a| a.id}

    services = JABA::Services.new
    fm = JABA::FileManager.new(services)
    file = fm.new_file("#{JABA.grab_bag_dir}/#{@name}.jaba")
    w = file.writer

    @type_name = "#{@name}_rule"

    w << "type :#{@type_name} do" # TODO
    w << ""
    w << "  title '#{@display_name}'"
    w << ""

    @attrs.each do |a|
      if a.array
        w.write_raw '  attr_array'
      else
        w.write_raw '  attr'
      end
      w << " :#{a.id}, type: :#{a.type} do"
      w << "    title '#{a.title}'"
      w << "    note '#{a.notes}'" if a.notes
      if a.type == :choice
        w << "    items #{a.choices.inspect}"
      end
      w << "  end"
      w << ""
    end
    w << "end"
    w << ""

    w << "open_type :cpp_config do"
    w << "  attr :#{@name}, type: :node do"
    w << "    title '#{@name} custom build tool'"
    w << "    node_type :#{@type_name}"
    w << "  end"
    w << "end"
    w << ""

    print "#{file.filename} "
    case file.write
    when :ADDED
      puts "created"
    when :MODIFIED
      puts "modified"
    when :UNCHANGED
      puts 'unchanged'
    end
  end

  ##
  #
  def add_attr(elem, type, array: false)
    attrs = elem.attributes

    return if attrs['Visible']&.downcase == 'false'

    name = attrs['Name']
    subtype = attrs['Subtype']

    display_name = if subtype
      elem.elements["#{elem.name}.DisplayName/sys:String"].text
    else
      attrs['DisplayName']
    end

    desc = if subtype
      elem.elements["#{elem.name}.Description/sys:String"].text
    else
      attrs['Description']
    end

    switch = attrs['Switch']

    notes = ''
    notes << desc.strip.ensure_end_with('.') if (desc && desc != display_name)

    if switch && !switch.strip.empty?
      notes << ' ' if !notes.empty?
      notes << "Sets #{switch}"
    end
    
    notes.gsub!("'",  "\"")
    notes.gsub!('&quot;', '"')

    a = OpenStruct.new
    a.id = name
    a.type = type
    a.array = array
    a.title = display_name
    a.notes = notes if !notes.empty?

    if type == :choice
      a.choices = []
      elem.elements.each('EnumValue') do |ev|
        a.choices << ev.attributes['Name']
      end
    end

    @attrs << a
  end

end

# TODO: get from command line
JabaTypeBuilder.new.to_jaba_type("C:/projects/GitHub/ouroveon/build/ispc-msbuild/ispc.xml")