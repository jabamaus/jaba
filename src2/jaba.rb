require "fileutils"
require "digest/sha1"
require_relative "../../jrf/libs/jrfutils/core_ext"

debug! if ARGV.include?("--debug") || ARGV.include?("-d")

require_relative "../../jrf/libs/jrfutils/api_builder"
require_relative "core_ext"
require_relative "version"
require_relative "defs"
require_relative "jdl_core"
require_relative "file_manager"
require_relative "node"
require_relative "attribute_type"
require_relative "attribute"
require_relative "attribute_array"
require_relative "attribute_hash"
require_relative "context"

module JABA

  # Input to pass to Jaba.
  #
  class Input
    attr_accessor :src_root
    attr_accessor :build_root
    attr_block :definitions
    attr_bool :verbose
    attr_bool :profile
    attr_accessor :global_attrs # Initialise global attrs from a hash of name to value(s)
  end

  class JabaError < StandardError
    attr_reader :file
    attr_reader :line
  end

  # Jaba entry point. Returns output hash object.
  #
  def self.run(want_exceptions: false, &block)
    c = Context.new(want_exceptions, &block)
    c.execute
    return c.output
  end
end

require_relative "jdl"

if __FILE__ == $PROGRAM_NAME
  require_relative "../../jrf/libs/jrfutils/cmdline"

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
        c.add_value("--build-root -B", help: "Set build root", var: :build_root)
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

      output = JABA.run do |j|
        j.src_root = @src_root
        j.build_root = @build_root
        j.global_attrs = @globals
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
