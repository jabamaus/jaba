require_relative '../lib/jaba'

using JABACoreExt

class DocBuilder

  DOCS_REPO_DIR =               "#{JABA.install_dir}/../jaba_docs".cleanpath
  DOCS_HANDWRITTEN_DIR =        "#{DOCS_REPO_DIR}/handwritten"
  DOCS_MARKDOWN_DIR =           "#{DOCS_REPO_DIR}/markdown"
  DOCS_MARKDOWN_VERSIONED_DIR = "#{DOCS_REPO_DIR}/markdown/v#{JABA::VERSION}"
  DOCS_HTML_DIR =               "#{DOCS_REPO_DIR}/docs"

  MAMD_DIR = "#{__dir__}/../../MaMD/_builds".cleanpath

  # TODO: check exit codes

  def build
    if !File.exist?(DOCS_REPO_DIR)
      git_cmd("clone --branch docs --single-branch #{JABA.jaba_repo_url} #{DOCS_REPO_DIR}")
    end

    doc_temp = "#{__dir__}/doc_temp"

    if !File.exist?(doc_temp)
      FileUtils.mkdir(doc_temp)
    end
    IO.write("#{doc_temp}/dummy.jaba", "")

    op = JABA.run(want_exceptions: true) do |c|
      c.dry_run
      c.src_root = c.build_root = doc_temp
    end
    services = op[:services]

    @file_manager = services.file_manager
    @top_level_jaba_types = services.instance_variable_get(:@top_level_jaba_types)
    @jaba_attr_types = services.jaba_attr_types
    @jaba_attr_flags = services.instance_variable_get(:@jaba_attr_flags)

    Dir.glob("#{DOCS_HANDWRITTEN_DIR}/*.md").each do |md|
      FileUtils.copy_file(md, "#{DOCS_MARKDOWN_DIR}/#{md.basename}")
    end

    generate_reference_doc
    generate_examples_doc
    generate_faqs

    Dir.chdir(MAMD_DIR) do
      cmd = "MaMD_windows_amd64.exe -i \"#{DOCS_MARKDOWN_DIR}\" -o \"#{DOCS_HTML_DIR}\""
      puts cmd
      system(cmd)
    end
  end

  ##
  #
  def generate_reference_doc
    write_markdown_page('jaba_reference.md', 'Jaba language reference', versioned: true) do |w|
      w << ""

      # TODO: document include statement
      # TODO: document top level types
      # TODO: document how to define new types and attributes
      
      w << "- Types"
      @top_level_jaba_types.sort_by {|jt| jt.defn_id}.each do |jt|
        w << "  - [#{jt.defn_id}](#{jt.reference_manual_page})"
        jt.all_attr_defs_sorted.each do |ad|
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
      w << "> "
      w << "> _#{jt.title}_"
      w << "> "
      w << "> | Property | Value  |"
      w << "> |-|-|"
      md_row(w, 'defined in', "$(jaba_install)/#{jt.src_loc.describe(style: :rel_jaba_install, line: false)}")
      md_row(w, :notes, jt.notes.make_sentence)
      md_row(w, 'depends on', jt.dependencies.map{|d| "[#{d}](#{d.reference_manual_page})"}.join(", "))
      w << "> "
      w << ""
      jt.all_attr_defs_sorted.each do |ad|
        w << "<a id=\"#{ad.defn_id}\"></a>" # anchor for the attribute eg cpp-src
        w << "#### #{ad.defn_id}"
        w << "> _#{ad.title}_"
        w << "> "
        w << "> | Property | Value  |"
        w << "> |-|-|"
        # TODO: need to flag whether per-project/per-config etc
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
        md_row(w, :notes, ad.notes.make_sentence.to_markdown_links) if !ad.notes.empty?
        w << ">"
        if !ad.examples.empty?
          w << "> *Examples*"
          md_code(w, prefix: '>') do
            ad.examples.each do |e|
              e.split_and_trim_leading_whitespace do |line|
                w << "> #{line}"
              end
            end
          end
        end
      end
    end
  end

  def generate_examples_doc
    write_markdown_page('jaba_examples.md', 'Jaba examples', versioned: true) do |w|
      Dir.glob("#{JABA.examples_dir}/**/*.jaba").each do |example|
        next if example.basename == 'examples.jaba'
        str = @file_manager.read(example, fail_if_not_found: true)
        md_code(w) do
          # TODO: extract top comments and turn into formatted markdown
          str.split_and_trim_leading_whitespace do |line|
            w << line
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
  def write_markdown_page(md, title, versioned:)
    fn = versioned ? "#{DOCS_MARKDOWN_VERSIONED_DIR}/#{md}" : "#{DOCS_MARKDOWN_DIR}/#{md}"
    puts "Writing #{fn}"
    file = @file_manager.new_file(fn, capacity: 16 * 1024)
    w = file.writer
    w << "## #{title}"
    w << "[home](index.html)"
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

  def git_cmd(cmd)
    puts cmd
    system("git #{cmd}")
    puts 'Done!'
  end

end

if __FILE__ == $PROGRAM_NAME
  DocBuilder.new.build
end