require "fileutils"
require "tsort"
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

      # General non-cmd-specific options
      clm.register_cmd(:null, help: "") do |c|
        c.add_flag("--help", help: "Show help", var: :show_help)
        c.add_flag("--profile", help: "Profiles with ruby-prof gem", var: :profile, dev_only: true)
        c.add_flag("--verbose", help: "Prints extra information", var: :verbose)
        c.add_flag("--debug -d", help: "Start debugger", dev_only: true)
      end

      clm.register_cmd(:gen, help: "Regenerate buildsystem", default: true) do |c|
        c.add_value("--src-root -S", help: "Set src root", var: :src_root)
        c.add_key_values("--define -D", help: "Set global attribute value", var: :globals)
      end

      clm.register_cmd(:build, help: "Execute build")
      clm.register_cmd(:clean, help: "Clean build")
      
      clm.register_cmd(:convert, help: "Convert vcxproj to jaba spec") do |c|
        c.add_value("--vcxproj -p", help: "Path to vcxproj file", var: :vcxproj)
        c.add_value("--outdir -o", help: "Path to generated .jaba file. Defaults to cwd.", var: :outdir)
      end
      
      clm.register_cmd(:help, help: "Open jaba web help")

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
        convert_vcxproj
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

    def help_string = "Jaba build system generator v#{JABA::VERSION}"
    
    def error(msg)
      $stderr.puts msg
      exit 1
    end
  end

  def convert_vcxproj
    if !File.exist?(@vcxproj)
      error "#{@vcxproj} not found"
    end
    @outdir = Dir.getwd if @outdir.nil?
    require_relative 'vcxproj_converter'
    JABA::VcxprojConverter.new(@vcxproj, @outdir).run
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
