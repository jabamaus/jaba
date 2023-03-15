require_relative 'version'
require_relative 'core/services'

module JABA

  # Jaba entry point. Returns a json-like hash object containing a summary of what has been generated.
  #
  def self.run(want_exceptions: false, test_mode: false)
    s = Services.new(test_mode: test_mode)
    begin
      s.execute do
        yield s.input if block_given?
        s.run
      end
    rescue
      if want_exceptions
        raise
      else
        return s.output
      end
    end
  end

  # Input to pass to Jaba.
  #
  class Input
    # Input root. Defaults to current working directory.
    #
    attr_accessor :src_root

    # Output/dest root. Defaults to current working directory.
    #
    attr_accessor :build_root
    
    # Definitions in block form
    #
    attr_block :definitions
    
    # Execute as normal but don't write any files.
    #
    attr_bool :dry_run

    attr_bool :profile
    
    # Used during testing. Only loads the bare minimum definitions. Jaba will not be able to generate any projects in this mode. 
    #
    attr_bool :barebones

    attr_bool :dump_output
    
    attr_bool :dump_state

    attr_bool :verbose

    # Initialise global attrs from a hash of name to value(s)
    #
    attr_accessor :global_attrs
  end

  # Jaba Definition Language error.
  # Raised when there is an error in a definition. These errors should be fixable by the user by modifying the definition
  # file.
  #
  class JabaError < StandardError
    # The definition file the error occurred in.
    #
    attr_reader :file
    
    # The line in the definition file that the error occurred at.
    #
    attr_reader :line
  end
if __FILE__ == $PROGRAM_NAME

require_relative '../../jrf/libs/jrfutils/cmdline'

class Jaba
  
  def run
    clm = CmdlineManager.new(self, 'jaba')

    # General non-cmd-specific options
    clm.register_cmd(:null, help: '') do |c|
      c.add_flag('--help', help: 'Show help', var: :show_help)
      c.add_flag('--dry-run', help: 'Perform a dry run', var: :dry_run)
      c.add_flag('--profile', help: 'Profiles with ruby-prof gem', var: :profile, dev_only: true)
      c.add_flag('--verbose', help: 'Prints extra information', var: :verbose)
      c.add_flag('--debug -d', help: 'Start debugger', var: :debug, dev_only: true)
    end

    clm.register_cmd(:gen, help: 'Regenerate buildsystem', default: true) do |c|
      c.add_value('--src-root -S', help: 'Set src root', var: :src_root)
      c.add_value('--build-root -B', help: 'Set build root', var: :build_root)
      c.add_key_values('--define -D', help: 'Set global attribute value', var: :globals)
      c.add_flag('--dump-state', help: 'Dump state to json for debugging', var: :dump_state)
    end
    
    clm.register_cmd(:build, help: 'Execute build')
    clm.register_cmd(:clean, help: 'Clean build')
    clm.register_cmd(:help, help: 'Open jaba web help')

    clm.process
    clm.finalise

    if @debug
      debug!
    end
    
    if @show_help
      clm.show_help
    end
    
    if clm.cmd_specified?(:help)
      url = "#{JABA.jaba_docs_url}/v#{VERSION}"
      cmd = if OS.windows?
        'start'
      elsif OS.mac?
        'open'
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
      j.dry_run = @dry_run
      j.dump_state = @dump_state
      j.profile = @profile
      j.verbose = @verbose
    end

    if output[:error]
      error(output[:error])
      return 1
    end

    puts output[:summary]
    puts output[:warnings]
    return 0
  end

  def help_string = "Jaba build system generator v#{VERSION}"
  def error(msg) = $stderr.puts msg
end

exit(Jaba.new.run)

end
end
