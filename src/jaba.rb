require "fileutils"
require_relative "../../jrf/jrf/utils/tsort"
require_relative "../../jrf/jrf/utils/core_ext"

debug! if ARGV.include?("--debug") || ARGV.include?("-d")

require_relative "../../jrf/jrf/utils/api_exposer"
require_relative "core_ext"
require_relative "utils"
require_relative "version"
require_relative "context"
require_relative "jdl_builder"
require_relative "jdl/jdl_core"
require_relative "file_manager"
require_relative "node"
require_relative "attribute_type"
require_relative "attribute_flags"
require_relative "attribute"
require_relative "attribute_array"
require_relative "attribute_hash"
require_relative "vcxproj"
require_relative "vcxproj_windows"
require_relative "sln"

module JABA

  # Input to pass to Jaba.
  #
  class Input
    attr_accessor :src_root
    attr_block :definitions
    attr_bool :verbose
    attr_bool :profile
    attr_bool :want_exceptions # defaults to false
    attr_accessor :global_attrs_from_cmdline # Values will all be in string form
  end

  class JabaError < StandardError
    attr_reader :raw_message # Basic message without src location. Useful when wrapping exceptions.
  end

  Context.init

  # Jaba entry point. Returns output hash object.
  #
  def self.run(&block)
    c = Context.new(&block)
    c.execute
    c.output
  end
end

if __FILE__ == $PROGRAM_NAME
  require_relative "../../jrf/jrf/utils/cmdline"

  class Jaba
    def run
      clm = CmdlineManager.new(self, "jaba")
      clm.help "Jaba build system generator v#{JABA::VERSION}"

      # General non-cmd-specific options
      clm.cmd(:null, help: "") do |c|
        c.flag("--help", help: "Show help", var: :show_help)
        c.flag("--profile", help: "Profiles with ruby-prof gem", var: :profile, dev_only: true)
        c.flag("--verbose", help: "Prints extra information", var: :verbose)
        c.flag("--debug -d", help: "Start debugger", dev_only: true)
      end

      clm.cmd(:gen, help: "Regenerate buildsystem", default: true) do |c|
        c.value("--src-root -S", help: "Set src root", var: :src_root)
        c.key_values("--define -D", help: "Set global attribute value", var: :globals)
      end

      clm.cmd(:build, help: "Execute build")
      clm.cmd(:clean, help: "Clean build")

      clm.cmd(:convert, help: "Convert .sln to jaba spec") do |c|
        c.value("--vcxproj -p", help: "Path to .vcxporj file", var: :vcxproj)
        c.value("--sln -s", help: "Path to sln file", var: :sln)
        c.value("--outdir -o", help: "Parent directory of generated .jaba file. Defaults to cwd.", var: :outdir)
      end

      clm.cmd(:help, help: "Open jaba web help")

      clm.process
      clm.finalise

      if @show_help
        clm.show_help
      elsif clm.cmd_specified?(:help)
        cmd = if JABA::OS.windows?
            "start"
          elsif JABA::OS.mac?
            "open"
          else
            error "Unsupported platform"
          end
        system("#{cmd} #{JABA::DOCS_URL}")
      elsif clm.cmd_specified?(:gen)
        run_jaba
      elsif clm.cmd_specified?(:convert)
        vc_convert
      elsif clm.cmd_specified?(:build)
        # TODO
      elsif clm.cmd_specified?(:clean)
        # TODO
      else
        error "unrecognised command"
      end
    end

    def run_jaba
      @src_root = Dir.getwd if @src_root.nil?

      output = JABA.run do |j|
        j.src_root = @src_root
        j.global_attrs_from_cmdline = @globals
        j.profile = @profile
        j.verbose = @verbose
      end

      if output.nil? || output.empty?
        error "INTERNAL ERROR: Jaba failed to return any output"
      end

      if output[:error]
        $stderr.puts(output[:error])
      end

      puts output[:summary]
      puts output[:warnings] if !output[:warnings].empty?
    end

    def error(msg)
      $stderr.puts msg
      exit 1
    end
  end

  def vc_convert
    require_relative 'vc_converter'
    @outdir = Dir.getwd if @outdir.nil?
    if @sln
      if !File.exist?(@sln)
        error "#{@sln} not found"
      end
      JABA::SlnConverter.new(@sln, @outdir).run
    end
    if @vcxproj
      if !File.exist?(@vcxproj)
        error "#{@vcxproj} not found"
      end
      JABA::VcxprojConverter.new(@vcxproj, @outdir).process.write.generate
    end
  end

  begin
    Jaba.new.run
  rescue => e
    $stderr.puts e.full_message
    exit 1
  rescue SystemExit => e
    exit(e.status)
  end
end
