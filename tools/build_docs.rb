require_relative 'common'
require_relative '../examples/gen_all'

class DocBuilder

  include CommonUtils
  
  DOCS_REPO_DIR =               "#{__dir__}/../../jaba_docs".cleanpath
  DOCS_HANDWRITTEN_DIR =        "#{DOCS_REPO_DIR}/handwritten"
  DOCS_MARKDOWN_DIR =           "#{DOCS_REPO_DIR}/markdown"
  DOCS_MARKDOWN_VERSIONED_DIR = "#{DOCS_REPO_DIR}/markdown/v#{JABA::VERSION}"
  DOCS_HTML_DIR =               "#{DOCS_REPO_DIR}/docs"

  MAMD_DIR = "#{__dir__}/../../MaMD/_builds".cleanpath

  # TODO: check exit codes

  def build
    if !File.exist?(DOCS_REPO_DIR)
      git_cmd("clone --branch docs --single-branch #{JABA_REPO_URL} #{DOCS_REPO_DIR}")
    end

    doc_temp = "#{__dir__}/temp/doc"

    if !File.exist?(doc_temp)
      FileUtils.makedirs(doc_temp)
    end

    # Delete markdown and docs dirs completely as they will be regenerated
    #
    if File.exist?(DOCS_HTML_DIR)
      FileUtils.remove_dir(DOCS_HTML_DIR)
    end

    if File.exist?(DOCS_MARKDOWN_DIR)
      FileUtils.remove_dir(DOCS_MARKDOWN_DIR)
    end

    FileUtils.mkdir(DOCS_HTML_DIR)
    FileUtils.mkdir(DOCS_MARKDOWN_DIR)

    FileUtils.copy_file("#{DOCS_HANDWRITTEN_DIR}/mamd.css", "#{DOCS_HTML_DIR}/mamd.css")
    
    @file_manager = JABA::FileManager.new

    # Build documentable API objects
    JABA::Context.new
    @jdl = JABA::JDLBuilder.new

    generate_handwritten
    generate_versioned_index
    generate_reference_doc
    generate_examples
    generate_faqs

    Dir.chdir(MAMD_DIR) do
      cmd = "MaMD_windows_amd64.exe -i \"#{DOCS_MARKDOWN_DIR}\" -o \"#{DOCS_HTML_DIR}\""
      puts cmd
      system(cmd)
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

  def write_reference_tree_node(node_def, w, depth)
    w << "#{'    ' * depth}- [#{node_def.name}](#{node_def.name}.html)"
    depth += 1
    node_def.attr_defs.each do |ad|
      w << "#{'    ' * depth}- [#{ad.name}](#{node_def.name}.html##{ad.name})"
      if ad.type_id == :compound
        depth += 1
        ad.compound_def.attr_defs.each do |c|
          w << "#{'    ' * depth}- [#{c.name}](#{node_def.name}.html##{c.name})"
        end
        depth -= 1
      end
    end
    node_def.node_defs.each do |child|
      write_reference_tree_node(child, w, depth)
    end
    depth -= 1
  end

  def visit_node_def(node_def, &block)
    yield node_def
    node_def.node_defs.each do |child|
      visit_node_def(child, &block)
    end
  end

  def generate_reference_doc
    write_markdown_page('jaba_reference.md', 'Jaba language reference', versioned: true) do |w|
      w << ""

      write_reference_tree_node(@jdl.top_level_node_def, w, 0)

      visit_node_def(@jdl.top_level_node_def) do |nd|
       generate_node_reference(nd)
      end
      w << ""
    end
  end

  def generate_node_reference(n)
    write_markdown_page("#{n.name}.md", n.name, versioned: true) do |w|
      w << "[#{JABA::VERSION} reference home](jaba_reference.html)  "
      w << "> "
      w << "> _#{n.title}_"
      w << "> "
      w << "> #{n.notes.make_sentence}"
      w << "> "
      w << ""
      w << "#{n.attr_defs.size} attribute#{n.attr_defs.size == 1 ? '' : 's'}:  "
      n.attr_defs.each do |ad|
        w << "- [#{ad.name}](##{ad.name})"
      end
      w << ""
      n.attr_defs.each do |ad|
        write_attr_def(ad, w)
        if ad.type_id == :compound
          ad.compound_def.attr_defs.each do |ca|
            # TODO: distinguish compound attrs somehow. Maybe use path instead of just name
            write_attr_def(ca, w)
          end
        end
      end
    end
  end

  def write_attr_def(ad, w)
    w << "<a id=\"#{ad.name}\"></a>" # anchor for the attribute eg 'src_ext'
    w << "#### #{ad.name}"
    w << "> _#{ad.title}_"
    w << "> "
    w << "> #{ad.notes.make_sentence.to_markdown_links(@services)}" if !ad.notes.empty?
    w << "> "
    w << "> | Property | Value  |"
    w << "> |-|-|"
    
    type = String.new
    if ad.type_id
      type << "#{ad.type_id.inspect}"
    end
    if ad.array?
      type << " array"
    elsif ad.hash?
      type << " hash"
    end
    md_row(w, :type, type)
    #ad.jaba_attr_type.get_reference_manual_rows(ad)&.each do |id, value|
    #  md_row(w, id, value)
    #end
    md_row(w, :default, ad.default.proc? ? nil : !ad.default.nil? ? ad.default.inspect : nil)
    md_row(w, :flags, ad.flags.map(&:inspect).join(', '))
    md_row(w, :options, ad.flag_options.map(&:inspect).join(', '))
    w << ">"
    if !ad.examples.empty?
      w << "> *Examples*"
      md_code(w, prefix: '>') do
        ad.examples.each do |e|
          split_and_trim_leading_whitespace(e).each do |line|
            w << "> #{line}"
          end
        end
      end
    end
  end

  def generate_examples
    iterate_examples do |dirname, full_dir|
      write_markdown_page("#{dirname}.md", dirname, versioned: true) do |w|
        Dir.glob("#{full_dir}/*.jaba").each do |jaba_file|
          str = @file_manager.read(jaba_file, fail_if_not_found: true)
          md_code(w) do
            # TODO: extract top comments and turn into formatted markdown
            split_and_trim_leading_whitespace(str).each do |line|
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
      md_small(w, "This page applies to v#{JABA::VERSION}<br>")
    end
    if want_home
      w << if versioned
        "[home](../index.html)  "
      else
        "[home](index.html)  "
      end
      if versioned && versioned_home
        w << "[#{JABA::VERSION} home](index.html)  "
      end
    end
    yield w
    md_small(w, "Generated by #{html_link('https://github.com/ishani/MaMD', 'MaMD')} " \
      "which uses #{html_link('https://github.com/yuin/goldmark', 'Goldmark')}, " \
      "#{html_link('https://github.com/alecthomas/chroma', 'Chroma')}, " \
      "#{html_link('https://rsms.me/inter', 'Inter')} and " \
      "#{html_link('https://github.com/tonsky/FiraCode', 'FiraCode')}")
    file.write
  end

  def html_link(href, text)
    "<a href=\"#{href}\">#{text}</a>"
  end

  def md_small(w, text)
    w << "<sub><sup>#{text}</sup></sub>"
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

  # Used when generating code example blocks in reference manual.
  #
  def split_and_trim_leading_whitespace(paragraph)
    lines = paragraph.split("\n")
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

end

class String
  # Convert all variables specified as $(cpp#varname) (which themselves reference attribute names) into markdown links
  # eg [$(cpp#varname)](#jaba_type_cpp.html#varname).
  #
  def to_markdown_links(services)
    gsub(/(\$\((.*?)\))/) do
      mdl = "[#{$1}]"
      attr_ref = $2
      mdl << if attr_ref =~ /^(.*?)#(.*)/
        type = services.get_jaba_type($1.to_sym)
        "(#{type.reference_manual_page}##{$2})"
      else
        "(##{attr_ref})"
      end
      mdl
    end
  end
end

class Array
  def make_sentence
    s = String.new
    each do |l|
      s.concat(l.capitalize_first)
      s.ensure_end_with!('. ')
    end
    s
  end
end

if __FILE__ == $PROGRAM_NAME
  DocBuilder.new.build
end