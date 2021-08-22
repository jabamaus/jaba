require_relative 'common'

using JABACoreExt

class JabaTypeBuilder

  ##
  #
  def to_jaba_type(xml_file)
    if !File.exist?(xml_file)
      raise "#{xml_file} does not exist"
    end
    @attrs = []
    @content = IO.read(xml_file)

    @name = 'ispc' # TODO
    @type_name = "#{@name}_rule"
    
    scan_for_props('<BoolProperty', '(</BoolProperty>| />)') do |c|
      add_attr(c, :bool)
    end
    scan_for_props('<IntProperty', '(</IntProperty>| />)') do |c|
      add_attr(c, :int)
    end
    scan_for_props('<StringProperty', '(</StringProperty>| />)') do |c|
      add_attr(c, :string)
    end
    scan_for_props('<StringListProperty', '(</StringListProperty>| />)') do |c|
      add_attr(c, :string, array: true)
    end
    scan_for_props('<EnumProperty', '</EnumProperty>') do |c|
      add_attr(c, :choice)
    end

    @attrs.sort_by!{|a| a.id}

    services = JABA::Services.new
    fm = JABA::FileManager.new(services)
    file = fm.new_file("#{JABA.grab_bag_dir}/#{@name}.jaba")
    w = file.writer

    w << "type :#{@type_name} do" # TODO
    w << ""
    w << "  title 'TODO'"
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
  def scan_for_props(start, end_)
    blocks = []
    @content.scan(/(#{start}(.*?)#{end_})/m) do |match|
      blocks << match[0]
      yield match[1].strip
    end
    blocks.each do |b|
      @content.sub!(b, '')
    end
  end

  ##
  #
  def get_prop(c, prop, optional: false)
    if c !~ /#{prop}="(.*?)"/
      if optional
        return nil
      else
        raise "Could not read '#{prop}' from #{c}"
      end
    end
    Regexp.last_match(1)
  end

  ##
  #
  def add_attr(c, type, array: false)
    return if c =~ /<DataSource/

    visible = get_prop(c, 'Visible', optional: true)
    return if (visible && visible.downcase == 'false')

    has_subtype = get_prop(c, 'Subtype', optional: true) ? true : false

    name = get_prop(c, 'Name')

    display_name = if has_subtype
      if c !~ /DisplayName>.*?<sys:String>(.*?)<\/sys:String>/m
        raise "Could not extract sub type display name from #{c}"
      end
      Regexp.last_match(1)
    else
      get_prop(c, 'DisplayName')
    end
    
    desc = if has_subtype
      if c !~ /Description>.*?<sys:String>(.*?)<\/sys:String>/m
        raise "Could not extract sub type display name from #{c}"
      end
      Regexp.last_match(1)
    else
      get_prop(c, 'Description', optional: true)
    end

    switch = type != :choice ? get_prop(c, 'Switch', optional: true) : nil

    notes = ''
    notes << desc.strip.ensure_end_with('.') if (desc && desc != display_name)
    if switch
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
      c.scan(/<EnumValue(.*?)\/>/m) do |match|
        a.choices << get_prop(match[0], 'Name')
      end
    end

    @attrs << a
  end
end

# TODO: get from command line
JabaTypeBuilder.new.to_jaba_type("C:/projects/GitHub/ouroveon/build/ispc-msbuild/ispc.xml")