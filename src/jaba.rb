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
      clm.register_cmd(:help, help: "Open jaba web help")

      clm.process
      clm.finalise

      if @show_help
        clm.show_help
        return 0
      end

      if clm.cmd_specified?(:help)
        url = "#{JABA.jaba_docs_url}/v#{VERSION}"
        cmd = if OS.windows?
            "start"
          elsif OS.mac?
            "open"
          else
            error("Unsupported platform")
            return 1
          end
        system("#{cmd} #{url}")
        return 0
      end

      @src_root = Dir.getwd if @src_root.nil?

      output = JABA.run do |j|
        j.src_root = @src_root
        j.global_attrs_from_cmdline = @globals
        j.profile = @profile
        j.verbose = @verbose
      end

      if output.nil? || output.empty?
        error("INTERNAL ERROR: Jaba failed to return any output")
        return 1
      end

      if output[:error]
        error(output[:error])
        return 1
      end

      puts output[:summary]
      puts output[:warnings] if !output[:warnings].empty?
      return 0
    end

    def help_string = "Jaba build system generator v#{JABA::VERSION}"
    def error(msg) = $stderr.puts msg
  end

  exit(Jaba.new.run)
end
