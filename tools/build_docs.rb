require_relative "../../jrf/libs/jrfutils/cmdline_tool"
require_relative 'common'
require_relative '../examples/gen_all'

class String
  def escape_md_label = gsub("_", "\\_")

  # Used when generating code example blocks in reference manual.
  #
  def split_and_trim_leading_whitespace
    lines = split("\n")
    return lines if lines.empty?
    lines.shift if lines[0].empty?
    lines.last.rstrip!
    lines.pop if lines.last.empty?

    if lines[0] =~ /^(\s+)/
      lw = Regexp.last_match(1)
      lines.each do |l|
        l.delete_prefix!(lw)
      end
    end
    lines
  end

  # Convert all variables specified as $(target#varname) (which themselves reference attribute names) into markdown links
  # eg [$(target#varname)](#target.html#varname).
  #
  def to_markdown_links(jdl_builder)
    gsub(/(\$\((.*?)\))/) do
      mdl = "[#{$1}]"
      attr_ref = $2
      mdl << if attr_ref =~ /^(.*?)#(.*)/
        nd = jdl_builder.lookup_node_def($1)
        "(#{nd.reference_manual_page}##{$2})"
      else
        "(##{attr_ref})"
      end
      mdl
    end
  end
end

class JABA::JDLDefinition
  def md_label = name.escape_md_label
end

class JABA::MethodDef
  def md_label = "#{name}()".escape_md_label
end

class JABA::NodeDef
  def attrs_and_methods_sorted
    all = []
    if parent_node_def # common attrs are not included in root
      all.concat(@jdl_builder.common_attr_node_def.attr_defs)
    end
    all.concat(node_defs)
    all.concat(attr_defs)
    all.concat(method_defs)
    all.sort_by!{|d| d.name}
    all
  end
  
  def visit(depth = 0, &block)
    yield self, depth
    depth += 1
    node_defs.each do |child|
      child.visit(depth, &block)
    end
    depth -= 1
  end
end

class DocBuilder < CmdlineTool
  DOCS_REPO_DIR =               "#{__dir__}/../../jaba_docs".cleanpath
  DOCS_HANDWRITTEN_DIR =        "#{DOCS_REPO_DIR}/handwritten"
  DOCS_MARKDOWN_DIR =           "#{DOCS_REPO_DIR}/markdown"
  DOCS_MARKDOWN_VERSIONED_DIR = "#{DOCS_REPO_DIR}/markdown/v#{JABA::VERSION}"
  DOCS_HTML_DIR =               "#{DOCS_REPO_DIR}/docs"

  MAMD_DIR = "#{__dir__}/../../MaMD/_builds".cleanpath
  MAMD_EXE = "MaMD_windows_amd64.exe"

  def help_string = "Buids jaba docs"
  def run
    process_cmd_line("djaba") do |c|
    end
    build
  end

  def build
    if !File.exist?(DOCS_REPO_DIR)
      git_cmd("clone --branch docs --single-branch #{JABA_REPO_URL} #{DOCS_REPO_DIR}")
    end

    doc_temp = "#{__dir__}/temp/doc"

    FileUtils.makedirs(doc_temp) if !File.exist?(doc_temp)

    # Delete markdown and docs dirs completely as they will be regenerated
    FileUtils.remove_dir(DOCS_HTML_DIR) if File.exist?(DOCS_HTML_DIR)
    FileUtils.remove_dir(DOCS_MARKDOWN_DIR) if File.exist?(DOCS_MARKDOWN_DIR)
    FileUtils.mkdir(DOCS_HTML_DIR)
    FileUtils.mkdir(DOCS_MARKDOWN_DIR)

    FileUtils.copy_file("#{DOCS_HANDWRITTEN_DIR}/mamd.css", "#{DOCS_HTML_DIR}/mamd.css")
    
    ctxt = JABA::Context.new
    @file_manager = ctxt.file_manager
    @jdl = JABA::JDLBuilder.new

    generate_handwritten
    generate_versioned_index
    generate_reference_doc
    generate_examples
    generate_faqs

    if !File.exist?(MAMD_DIR)
      fail "#{MAMD_DIR} not found"
    end

    Dir.chdir(MAMD_DIR) do
      if !File.exist?(MAMD_EXE)
        fail "#{MAMD_EXE} not found in #{MAMD_DIR}"
      end
      shell_cmd("#{MAMD_EXE} -i \"#{DOCS_MARKDOWN_DIR}\" -o \"#{DOCS_HTML_DIR}\"")
    end
  end

  def generate_handwritten
    Dir.glob("#{DOCS_HANDWRITTEN_DIR}/*.md").each do |md|
      c = IO.read(md)
      basename = md.basename
      if c !~ /^## (.+)/
        raise "#{md} has invalid title"
      end
      title = Regexp.last_match(1)
      c.sub!(/^## .+/, '')

      want_home = basename == 'index.md' ? false : true
      write_markdown_page(md.basename, title, want_home: want_home, versioned: false) do |w|
        w << c
      end
    end
  end

  def generate_versioned_index
    write_markdown_page('index.md', 'Jaba docs', versioned: true, versioned_home: false) do |w|
      w << ""
      w << "- [Jaba language reference](jaba_reference.html)"
      w << "- Examples"
      iterate_examples do |dirname|
        w << "  - [#{dirname}](#{dirname}.html)"
      end
      w << ""
    end
  end

  def write_reference_tree_node(node_def, w, depth, skip_self: false)
    if !skip_self
      w << "#{'    ' * depth}- [#{node_def.md_label}](#{node_def.reference_manual_page}) #{node_def.title}"
      depth += 1
    end
    # TODO: generalise compound attrs
    node_def.attrs_and_methods_sorted.each do |d|
      w << "#{'    ' * depth}- [#{d.md_label}](#{node_def.reference_manual_page}##{d.name}) #{d.title} #{d.attribute? && d.has_flag?(:read_only) ? "(read only)" : ""}"
      if d.attribute? && d.type_id == :compound
        depth += 1
        d.compound_def.attr_defs.each do |c|
          w << "#{'    ' * depth}- [#{c.md_label}](#{node_def.reference_manual_page}##{c.name}) #{c.title}"
        end
        depth -= 1
      end
    end
  end

  def generate_reference_doc
    write_markdown_page('jaba_reference.md', 'Jaba language reference', versioned: true) do |w|
      w << ""
      @jdl.top_level_node_def.visit do |nd, depth|
        write_reference_tree_node(nd, w, depth)
        generate_node_reference(nd)
      end
      w << ""
      w << "#### Global methods"
      write_reference_tree_node(@jdl.global_methods_node_def, w, 0, skip_self: true)
      generate_node_reference(@jdl.global_methods_node_def)
      w << ""
    end
  end

  def write_notes(w, notes)
    notes.each do |n|
      w << "> - #{n.to_markdown_links(@jdl)}"
    end
  end

  def generate_node_reference(n)
    write_markdown_page("#{n.name}.md", n.name, versioned: true) do |w, nav|
      nav << "[#{JABA::VERSION} reference home](jaba_reference.html)"
      w << "> "
      w << "> _#{n.title}_"
      w << "> "
      write_notes(w, n.notes)
      w << "> "
      w << ""
      all = n.attrs_and_methods_sorted
      w << "#{all.size} member#{all.size == 1 ? '' : 's'}:  "
      w << ""

      all.each do |d|
        w << "- [#{d.md_label}](##{d.name})"
       end

      all.each do |d|
        if d.attribute?
          write_attr_def(d, w)
          # TODO: generalise compound attrs
          if d.type_id == :compound
            d.compound_def.attr_defs.each do |ca|
              # TODO: distinguish compound attrs somehow. Maybe use path instead of just name
              write_attr_def(ca, w)
            end
          end
        else # method
          write_method_def(d, w)
        end
      end
    end
  end

  def write_attr_def(ad, w)
    w << "<a id=\"#{ad.name}\"></a>" # anchor for the attribute eg 'src_ext'
    w << "#### #{ad.md_label}"
    w << "> _#{ad.title}_"
    w << "> "
    write_notes(w, ad.notes)
    w << "> "
    w << "> | Property | Value  |"
    w << "> |-|-|"
    
    type = if ad.single?
      "#{ad.type_id}"
    elsif ad.array?
      "#{ad.type_id} array"
    elsif ad.hash?
      "hash (#{ad.key_type.name} => #{ad.type_id})"
    end
    md_row(w, :type, type)
    #ad.jaba_attr_type.get_reference_manual_rows(ad)&.each do |id, value|
    #  md_row(w, id, value)
    #end
    md_row(w, :default, ad.default.proc? ? nil : !ad.default.nil? ? ad.default.inspect : nil)
    md_row(w, :options, ad.flag_options.map(&:inspect).join(', '))
    w << ">"
    if !ad.examples.empty?
      w << "> *Examples*"
      md_code(w, prefix: '>') do
        ad.examples.each do |e|
          e.split_and_trim_leading_whitespace.each do |line|
            w << "> #{line}"
          end
        end
      end
    end
  end
  
  def write_method_def(d, w)
    w << "<a id=\"#{d.name}\"></a>"
    w << "#### #{d.md_label}"
    w << "> _#{d.title}_"
    w << "> "
    write_notes(w, d.notes)
  end

  def generate_examples
    iterate_examples do |dirname, full_dir|
      write_markdown_page("#{dirname}.md", dirname, versioned: true) do |w|
        Dir.glob("#{full_dir}/*.jaba").each do |jaba_file|
          str = @file_manager.read(jaba_file, fail_if_not_found: true)
          md_code(w) do
            # TODO: extract top comments and turn into formatted markdown
            str.split_and_trim_leading_whitespace.each do |line|
              w << line
            end
          end
        end
      end
    end
  end

  def generate_faqs
    # TODO: check for duplicate ids
    write_markdown_page('jaba_faqs.md', 'Jaba FAQs', versioned: false) do |w|
      faqs = {}
      IO.read("#{DOCS_HANDWRITTEN_DIR}/faqs_src.txt").scan(/^\[(.*?)\]\s*\[(.*?)\](.*?)----[-]*/m) do |anchor, section, entry|
        lines = entry.split("\n")
        faq = lines.shift.lstrip
        answer = lines.join("\n").strip
        entry = faqs[section]
        if entry.nil?
          faqs[section] = []
        end
        faqs[section] << [faq, anchor, answer]
      end
      w << ""
      faqs.each do |s, entries|
        w << "- [#{s}](##{s})"
        entries.each do |e|
          w << "  - [#{e[0]}](##{e[1]})"
        end
      end
      w << ""
      faqs.each do |s, entries|
        w << "<a id=\"#{s}\"></a>"
        w << "## #{s}"
        entries.each do |e|
          w << "<a id=\"#{e[1]}\"></a>"
          w << "#### #{e[0]}"
          w << "#{e[2]}"
          w << ""
        end
      end
      w << ""
    end
  end

  def write_markdown_page(md, title, versioned:, want_home: true, versioned_home: true)
    fn = versioned ? "#{DOCS_MARKDOWN_VERSIONED_DIR}/#{md}" : "#{DOCS_MARKDOWN_DIR}/#{md}"
    puts "Writing #{fn}"
    file = @file_manager.new_file(fn)
    w = file.writer
    w << "## #{title}"
    if versioned
      w << md_small("This page applies to v#{JABA::VERSION}<br>")
    end
    nav = []
    if want_home
      nav << if versioned
        "[home](../index.html)"
      else
        "[home](index.html)"
      end
      if versioned && versioned_home
        nav << "[#{JABA::VERSION} home](index.html)"
      end
    end
    wa = file.work_area
    yield wa, nav
    w << nav.join(" > ")
    w.write_raw(wa)
    w << md_small("Generated on #{Time.now.strftime('%d-%B-%y at %H:%M:%S')} by #{html_link('https://github.com/ishani/MaMD', 'MaMD')} " \
      "which uses #{html_link('https://github.com/yuin/goldmark', 'Goldmark')}, " \
      "#{html_link('https://github.com/alecthomas/chroma', 'Chroma')}, " \
      "#{html_link('https://rsms.me/inter', 'Inter')} and " \
      "#{html_link('https://github.com/tonsky/FiraCode', 'FiraCode')}")
    file.write
  end

  def html_link(href, text)
    "<a href=\"#{href}\">#{text}</a>"
  end

  def md_small(text)
    "<sub><sup>#{text}</sup></sub>"
  end

  def md_code(w, prefix: nil)
    w << "#{prefix}```ruby"
    yield
    w << "#{prefix}```"
    w << ""
  end
  
  def md_row(w, p, v)
    w << "> | _#{p}_ | #{v} |"
  end
end

if __FILE__ == $PROGRAM_NAME
  DocBuilder.new.run
end