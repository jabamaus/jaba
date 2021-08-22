require_relative 'common'
require_relative '../examples/gen_all'

using JABACoreExt

class DocBuilder

  include CommonUtils
  
  DOCS_REPO_DIR =               "#{JABA.install_dir}/../jaba_docs".cleanpath
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

    doc_temp = "#{__dir__}/doc_temp"

    if !File.exist?(doc_temp)
      FileUtils.mkdir(doc_temp)
    end
    IO.write("#{doc_temp}/dummy.jaba", "")

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
    
    op = JABA.run(want_exceptions: true) do |c|
      c.src_root = c.build_root = doc_temp
      c.argv = ['-D', 'target_hosts', 'vs2019']
    end
    @services = op[:services]

    @file_manager = @services.file_manager
    @top_level_jaba_types = @services.instance_variable_get(:@top_level_jaba_types)
    @jaba_attr_types = @services.jaba_attr_types
    @jaba_attr_flags = @services.instance_variable_get(:@jaba_attr_flags)

    Dir.glob("#{DOCS_HANDWRITTEN_DIR}/*.md").each do |md|
      FileUtils.copy_file(md, "#{DOCS_MARKDOWN_DIR}/#{md.basename}")
    end

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

  ##
  #
  def generate_versioned_index
    # TODO: auto-add to main handwritten index
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

  ##
  #
  def generate_reference_doc
    write_markdown_page('jaba_reference.md', 'Jaba language reference', versioned: true) do |w|
      w << ""
      w << "- Types"
      @top_level_jaba_types.sort_by {|jt| jt.defn_id}.each do |jt|
        w << "  - [#{jt.defn_id}](#{jt.reference_manual_page})"
        jt.attribute_defs.each do |ad|
          w << "    - [#{ad.defn_id}](#{jt.reference_manual_page}##{ad.defn_id})"
        end
      end

      @top_level_jaba_types.each do |jt|
        generate_jaba_type_reference(jt)
      end

      w << "- Attribute types"
      @jaba_attr_types.each do |at|
        w << "  - #{at.id}"
      end

      w << "- Attribute variants"
      w << "  - single"
      w << "  - array"
      w << "  - hash"

      w << "- Attribute flags"
      @jaba_attr_flags.each do |af|
        w << "  - #{af.id}"
      end
      w << ""
    end
  end

  ##
  #
  def generate_jaba_type_reference(jt)
    write_markdown_page(jt.reference_manual_page(ext: '.md'), "#{jt.defn_id}", versioned: true) do |w|
      w << ""
      w << "> "
      w << "> _#{jt.title}_"
      w << "> "
      w << "> #{jt.notes.make_sentence}"
      w << "> "
      w << "> | Property | Value  |"
      w << "> |-|-|"
      md_row(w, 'defined in', "$(jaba_install)/#{jt.src_loc.describe(style: :rel_jaba_install, line: false)}")
      md_row(w, 'depends on', jt.dependencies.map{|d| "[#{d}](#{d.reference_manual_page})"}.join(", "))
      w << "> "
      w << ""
      w << "Attributes:  "
      jt.attribute_defs.each do |ad|
        w << "- [#{ad.defn_id}](##{ad.defn_id})"
      end
      w << ""
      jt.attribute_defs.each do |ad|
        w << "<a id=\"#{ad.defn_id}\"></a>" # anchor for the attribute eg 'src_ext'
        w << "#### #{ad.defn_id}"
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
          type << " []"
        elsif ad.hash?
          type << " {}"
        end
        md_row(w, :type, type)
        ad.jaba_attr_type.get_reference_manual_rows(ad)&.each do |id, value|
          md_row(w, id, value)
        end
        md_row(w, :default, ad.default.proc? ? nil : !ad.default.nil? ? ad.default.inspect : nil)
        md_row(w, :flags, ad.flags.map(&:inspect).join(', '))
        md_row(w, :options, ad.flag_options.map(&:inspect).join(', '))
        md_row(w, 'defined in', "$(jaba_install)/#{ad.src_loc.describe(style: :rel_jaba_install, line: false)}")
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

  ##
  #
  def generate_faqs
    # TODO: check for duplicate ids
    write_markdown_page('jaba_faqs.md', 'Jaba FAQs', versioned: false) do |w|
      faqs = {}
      IO.read("#{DOCS_HANDWRITTEN_DIR}/faqs_src.txt").scan(/^(.*?):(.*?)---/m) do |section, entry|
        lines = entry.split("\n")
        faq = lines.shift.lstrip
        faq_id = faq.slice(0, 20).delete(' ')
        answer = lines.join("\n").strip
        entry = faqs[section]
        if entry.nil?
          faqs[section] = []
        end
        faqs[section] << [faq, faq_id, answer]
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

  ##
  # TODO: ensure footer goes in handwritten markdown pages
  def write_markdown_page(md, title, versioned:, versioned_home: true)
    fn = versioned ? "#{DOCS_MARKDOWN_VERSIONED_DIR}/#{md}" : "#{DOCS_MARKDOWN_DIR}/#{md}"
    puts "Writing #{fn}"
    file = @file_manager.new_file(fn, capacity: 16 * 1024)
    w = file.writer
    title = "## #{title}"
    if versioned
      title << " v#{JABA::VERSION}"
    end
    w << title
    w << if versioned
      "[home](../index.html)  "
    else
      "[home](index.html)  "
    end
    if versioned && versioned_home
      w << "[#{JABA::VERSION} home](index.html)"
    end
    yield w
    md_small(w, "Generated by #{html_link('https://github.com/ishani/MaMD', 'MaMD')} " \
      "which uses #{html_link('https://github.com/yuin/goldmark', 'Goldmark')}, " \
      "#{html_link('https://github.com/alecthomas/chroma', 'Chroma')}, " \
      "#{html_link('https://rsms.me/inter', 'Inter')} and " \
      "#{html_link('https://github.com/tonsky/FiraCode', 'FiraCode')}")
    file.write
  end

  ##
  #
  def html_link(href, text)
    "<a href=\"#{href}\">#{text}</a>"
  end

  ##
  #
  def md_small(w, text)
    w << "<sub><sup>#{text}</sup></sub>"
  end

  ##
  #
  def md_code(w, prefix: nil)
    w << "#{prefix}```ruby"
    yield
    w << "#{prefix}```"
    w << ""
  end
  
  ##
  #
  def md_row(w, p, v)
    w << "> | _#{p}_ | #{v} |"
  end

  ##
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
        type = services.get_top_level_jaba_type($1.to_sym)
        "(#{type.reference_manual_page}##{$2})"
      else
        "(##{attr_ref})"
      end
      mdl
    end
  end

end

class Array

  ##
  #
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