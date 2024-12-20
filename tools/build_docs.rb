require "redcarpet"
require "coderay"
require 'cgi/util'
require_relative "../../jrf/jrf/utils/cmdline_tool"
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
  def md_label = name.to_s.escape_md_label
  def write_notes(w)
    notes.each do |n|
      w << "- #{CGI.escapeHTML(n).to_markdown_links(@jdl_builder)}"
    end
  end
end

class JABA::MethodDef
  def md_label = name.escape_md_label
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
  DOCS_MARKDOWN_DIR_VERSIONED = "#{DOCS_MARKDOWN_DIR}/v#{JABA::VERSION}"
  DOCS_HTML_DIR =               "#{DOCS_REPO_DIR}/docs"
  DOCS_HTML_DIR_VERSIONED =     "#{DOCS_HTML_DIR}/v#{JABA::VERSION}"

  def help_string = "Buids jaba docs"
  def run
    process_cmd_line("djaba") do |c|
      c.add_flag("--incremental -i", help: "Do not do a full clean", var: :incremental)
      c.add_flag("--dump-markdown -m", help: "Dump markdown for debugging", var: :dump_markdown)
    end
    build
  end

  def build
    if !File.exist?(DOCS_REPO_DIR)
      git_cmd("clone --branch docs --single-branch #{JABA_REPO_URL} #{DOCS_REPO_DIR}")
    end

    doc_temp = "#{__dir__}/temp/doc"

    FileUtils.makedirs(doc_temp) if !File.exist?(doc_temp)

    ensure_dir(DOCS_HTML_DIR)
    ensure_dir(DOCS_MARKDOWN_DIR, recreate: @dump_markdown)
    ensure_dir(DOCS_MARKDOWN_DIR_VERSIONED, recreate: @dump_markdown)

    FileUtils.copy_file("#{DOCS_HANDWRITTEN_DIR}/mamd.css", "#{DOCS_HTML_DIR}/mamd.css")
    
    ctxt = JABA::Context.new
    @file_manager = ctxt.file_manager
    @jdl = JABA::JDLBuilder.new
    @pages = []

    generate_handwritten
    generate_versioned_index
    generate_reference_doc
    generate_examples
    generate_faqs

    puts "Done!"
  end

  def ensure_dir(dir, recreate: true)
    if File.exist?(dir)
      if @incremental
        return
      else
        puts "Deleting #{dir}"
        FileUtils.remove_dir(dir)
      end
    end
    FileUtils.makedirs(dir) if recreate
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

      want_home = true
      want_date = false
      if basename == 'index.md'
        want_home = false
        want_date = true
      end

      write_page(md.basename_no_ext, title, want_home: want_home, want_date: want_date, versioned: false) do |w|
        w << c
      end
    end
  end

  def generate_versioned_index
    write_page('index', 'Jaba docs', versioned: true, want_date: true, versioned_home: false) do |w|
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
    write_page('jaba_reference', 'Jaba language reference', versioned: true) do |w|
      w << ""
      @jdl.top_level_node_def.visit do |nd, depth|
        write_reference_tree_node(nd, w, depth)
        generate_node_reference(nd)
      end
      w << ""
      w << "#### Global methods"
      w << ""
      w << "_Global methods are available in all contexts_"
      w << ""
      write_reference_tree_node(@jdl.global_methods_node_def, w, 0, skip_self: true)
      generate_node_reference(@jdl.global_methods_node_def)
      w << ""
    end
  end

  def generate_node_reference(n)
    write_page(n.name, n.name, versioned: true) do |w, nav|
      nav << "[#{JABA::VERSION} reference home](jaba_reference.html)"
      w.with_prefix "> " do
        w << ""
        w << "_#{n.title}_"
        w << ""
        n.write_notes(w)
        w << ""
      end
      w << ""
      all = n.attrs_and_methods_sorted
      w << "#{all.size} member#{all.size == 1 ? '' : 's'}:  "
      w << ""

      all.each do |d|
        w << "- [#{d.md_label}](##{d.name})"
      end
      w << ""
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
    w.with_prefix "> " do
      w << "_#{ad.title}_"
      w << ""
      w << "| K | V |"
      w << "|-|-|"
      md_row(w, :variant, ad.variant)

      if ad.hash?
        md_row(w, "key type", ad.key_type.name)
        md_row(w, "value type", ad.type_id)
      elsif ad.array?
        md_row(w, "elem type", ad.type_id)
      else
        md_row(w, "type", ad.type_id)
      end
      if ad.type_id == :choice
        md_row(w, "choices", ad.items.map{|i| i.inspect_unquoted}.join(", "))
      end

      if ad.default_set? && !ad.default.proc? && ad.default != ""
        md_row(w, :default, ad.default.inspect)
      end

      if !ad.notes.empty?
        w << ""
        w << "*Notes*"
        w << ""
        ad.write_notes(w)
      end

      if !ad.flag_option_defs.empty?
        w << ""
        w << "*Flags*"
        w << ""
        w << "| K | V |"
        w << "|-|-|"
        ad.flag_option_defs.each do |od|
          row = "_#{od.title}_"
          if !od.notes.empty?
            row << "<br>"
            od.notes.each do |n|
              row << "- " << n
            end
          end
          md_row(w, od.name.inspect_unquoted, row)
        end
        w << ""
      end

      if !ad.option_defs.empty?
        w << ""
        w << "*Options*"
        w.with_prefix "> " do
          ad.option_defs.each do |od|
            write_attr_def(od, w)
          end
        end
      end

      if !ad.examples.empty?
        w << "*Examples*"
        w << ""
        md_code(w, ad.examples.join("\n"))
      end
    end
    w << ""
  end
  
  def write_method_def(d, w)
    w << "<a id=\"#{d.name}\"></a>"
    w << "#### #{d.md_label}"
    w.with_prefix "> " do
      w << "_#{d.title}_"
      w << ""
      d.write_notes(w)
    end
  end

  def generate_examples
    iterate_examples do |dirname, full_dir|
      write_page(dirname, dirname, versioned: true) do |w|
        Dir.glob("#{full_dir}/*.jaba").each do |jaba_file|
          str = @file_manager.read(jaba_file, fail_if_not_found: true)
          w << ""
          md_code(w, str)
        end
      end
    end
  end

  def generate_faqs
    # TODO: check for duplicate ids
    write_page('jaba_faqs', 'Jaba FAQs', versioned: false) do |w|
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

  def write_page(basename, title, versioned:, want_home: true, want_date: false, versioned_home: true)
    dir = versioned ? DOCS_HTML_DIR_VERSIONED : DOCS_HTML_DIR
    fn = "#{dir}/#{basename}.html"
    css = "#{DOCS_HTML_DIR}/mamd.css".relative_path_from(dir)
    file = @file_manager.new_file(fn)
    w = file.work_area

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
    w2 = file.work_area
    yield w2, nav
    w << nav.join(" > ")
    w.write_raw(w2)
    w << md_small("Generated #{want_date ? "on #{Time.now.strftime('%d-%b-%y')} " : ''}" \
      "using #{html_link('https://github.com/vmg/redcarpet', 'Redcarpet')}, " \
      "#{html_link('https://github.com/rubychan/coderay', 'CodeRay')}, " \
      "#{html_link('https://rsms.me/inter', 'Inter')} and " \
      "#{html_link('https://github.com/tonsky/FiraCode', 'FiraCode')}" \
      ". css by Harry Denholm.")

    if @dump_markdown
      mddir = versioned ? DOCS_MARKDOWN_DIR_VERSIONED : DOCS_MARKDOWN_DIR
      mdf = "#{mddir}/#{basename}.md"
      puts "Dumping #{mdf}"
      IO.write(mdf, w.str)
    end

    xhtml = Redcarpet::Render::XHTML.new
    md = Redcarpet::Markdown.new(xhtml, tables: true, no_intra_emphasis: true, fenced_code_blocks: true)
    mdhtml = md.render(w.str)

    w3 = file.writer
    w3 << "<!DOCTYPE html>"
    w3 << "<\html xmlns=\"http://www.w3.org/1999/xhtml\" xml:lang=\"en-us\" lang=\"en-us\">"
    w3 << "  <head>"
    w3 << "    <title>#{title}</title>"
    w3 << "    <link rel=\"stylesheet\" href=\"https://rsms.me/inter/inter.css\">"
    w3 << "    <link rel=\"stylesheet\" href=\"https://fonts.googleapis.com/css?family=Fira+Code&display=swap\">"
    w3 << "    <link rel=\"stylesheet\" href=\"#{css}\">"
    w3 << "  </head>"
    w3 << "<body>"
    w3.write_raw(mdhtml)
    w3 << "</body>"
    w3 << "</html>"

    if file.write != :UNCHANGED
      puts "Writing #{file.filename.relative_path_from(DOCS_HTML_DIR)}"
    end
  end

  def html_link(href, text) = "<a href=\"#{href}\">#{text}</a>"
  def md_small(text) = "<sub><sup>#{text}</sup></sub>"
  def md_row(w, p, v) = w << "| _#{p}_ | #{v} |"

  def md_code(w, code)
    html = CodeRay.scan(code, :ruby).div
    html.split_and_trim_leading_whitespace.each do |line|
      w << line
    end
    w << ""
  end
end

if __FILE__ == $PROGRAM_NAME
  DocBuilder.new.run
end