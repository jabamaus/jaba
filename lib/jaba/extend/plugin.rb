module JABA

  using JABACoreExt
  
  ##
  #
  class PluginServices

    ##
    #
    def push_definition(...)
      @node_manager.push_definition(...)
    end

    ##
    #
    def make_node(...)
      @node_manager.make_node(...)
    end

    ##
    #
    def make_node_paths_absolute(...)
      @node_manager.make_node_paths_absolute(...)
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
    def execute_jdl(...)
      @services.execute_jdl(...)
    end

    ##
    #
    def node_from_handle(...)
      @node_manager.node_from_handle(...)
    end

    ##
    #
    def get_plugin(...)
      @services.get_plugin(...)
    end

    ##
    #
    def get_translator(...)
      @services.get_translator(...)
    end

    ##
    #
    def get_instance_definition(...)
      @services.get_instance_definition(...)
    end

    ##
    #
    def globals
      @services.globals
    end
    
    ##
    #
    def new_file(...)
      @services.file_manager.new_file(...)
    end

    ##
    #
    def jaba_warn(...)
      @services.jaba_warn(...)
    end

    ##
    #
    def log(...)
      @services.log(...)
    end

    ##
    #
    def register_cmd(...)
      @services.input_manager.register_cmd(...)
    end

    ##
    #
    def register_option(...)
      @services.input_manager.register_option(...)
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

    ##
    #
    def custom_handle_array_reference(attr, ref_node_id)
      false
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
