module JABA

  using JABACoreExt
  
  ##
  #
  class PluginServices

    ##
    #
    def make_node(sub_type_id: nil, name: nil, parent: nil, block_args: nil, &block)
      @node_manager.make_node(sub_type_id: sub_type_id, name: name, parent: parent, block_args: block_args, &block)
    end

    ##
    #
    def make_node_paths_absolute(node)
      @node_manager.make_node_paths_absolute(node)
    end

    ##
    #
    def nodes
      @node_manager.nodes
    end

    ##
    #
    def root_nodes
      @node_manager.root_nodes
    end

    ##
    #
    def execute_jdl(&block)
      @services.execute_jdl(&block)
    end

    ##
    #
    def node_from_handle(handle, fail_if_not_found: true, errobj: nil)
      @node_manager.node_from_handle(handle, fail_if_not_found: fail_if_not_found, errobj: errobj)
    end

    ##
    #
    def get_plugin(top_level_type_id)
      @services.get_plugin(top_level_type_id)
    end

    ##
    #
    def get_translator(id, fail_if_not_found: true)
      @services.get_translator(id, fail_if_not_found: fail_if_not_found)
    end

    ##
    #
    def globals
      @services.globals
    end
    
    ##
    #
    def new_file(filename, eol: :unix, encoding: nil, capacity: nil, track: true)
      @services.file_manager.new_file(filename, eol: eol, encoding: encoding, capacity: capacity, track: track)
    end

    ##
    #
    def jaba_warn(msg, errobj: nil)
      @services.jaba_warn(msg, errobj: errobj)
    end

    ##
    #
    def log(msg, severity = :INFO, section: false)
      @services.log(msg, severity, section: section)
    end

    ##
    #
    def register_cmd(id, help:, dev_only: false, &block)
      @services.input_manager.register_cmd(id, help: help, dev_only: dev_only, &block)
    end

    ##
    #
    def register_option(long, short: nil, help:, type: nil, var: nil, dev_only: false)
      @services.input_manager.register_option(long, short: short, help: help, type: type, var: var, dev_only: dev_only)
    end
    
  end

  ##
  #
  class Plugin

    attr_reader :services

    ##
    #
    def init
    end
    
    ##
    #
    def process_definition(definition)
    end

    ##
    #
    def make_host_objects
    end

    ##
    #
    def generate
    end

    ##
    #
    def build_jaba_output(root, out_dir)
    end
    
  end

  ##
  # The default plugin for a JabaType if none exists. Does no generation.
  #
  class DefaultPlugin < Plugin

    def process_definition(definition)
      services.make_node
    end

    def make_host_objects
      services.root_nodes.each do |n|
        services.make_node_paths_absolute(n)
      end
    end
  end

end
