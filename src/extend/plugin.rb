module JABA
  
  class PluginServices
    def make_node(...) = @node_manager.make_node(...)
    def nodes = @node_manager.nodes
    def root_nodes = @node_manager.root_nodes
    def execute_jdl(...) = @services.execute_jdl(...)
    def node_from_handle(...) = @services.node_from_handle(...)
    def get_plugin(...) = @services.get_plugin(...)
    def get_translator(...) = @services.get_translator(...)
    def get_instance_definition(...) = @services.get_definition(:instance, ...)
    def globals_node = @services.globals_node
    def globals = @services.globals
    def new_file(...) = @services.file_manager.new_file(...)
    def jaba_warn(...) = @services.jaba_warn(...)
    def log(...) = @services.log(...)
    def register_array_filter(...) = @services.register_array_filter(...)
  end

  class Plugin
    def services = @services
    def id = @id
    
    # Local constructor initialisation only.
    # 
    def init ; end
    
    # Give plugin a chance to do some initialisation before nodes are created. Dependent plugins that have already
    # been processed can be accessed here.
    #
    def pre_process_definitions ; end
    def process_definition(definition) = services.make_node(definition)
    def post_process_definitions ; end
    def generate ; end
    def build_output(root) ; end
  end
end
