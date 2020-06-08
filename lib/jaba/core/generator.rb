# frozen_string_literal: true

##
#
module JABA

  using JABACoreExt
  
  ##
  #
  class Generator
    
    ##
    #
    attr_reader :type_id # eg :cpp, :text
    attr_reader :root_nodes

    ##
    #
    def initialize(services, top_level_jaba_type)
      @services = services
      @top_level_jaba_type = top_level_jaba_type
      @type_id = @top_level_jaba_type.definition.id
      @definitions = []
      @root_nodes = []
      @nodes = []
      @node_lookup = {}
      @node_to_project = {}
      @reference_attrs_to_resolve = []
      init
    end

    ##
    #
    def process
      @definitions.each do |d|
        @services.log "Processing #{d.id} definition", section: true
        @current_definition = d
        @root_nodes << make_nodes
      end
      
      @reference_attrs_to_resolve.each do |a|
        a.map_value! do |ref|
          resolve_reference(a, ref)
        end
      end

      make_projects
      
      @nodes.each do |n|
        n.each_attr do |a|
          a.process_flags
        end
        
        # Make all nodes read only from this point, to help catch mistakes
        #
        n.make_read_only
      end
    end

    ##
    #
    def register_instance_definition(d)
      @definitions << d
    end

    ##
    #
    def get_generator(top_level_type_id)
      @services.get_generator(top_level_type_id)
    end

    ##
    # Call this from subclass
    #
    def make_node(sub_type_id: nil, name: nil, parent: nil, &block)
      depth = 0
      handle = nil

      if parent
        @services.jaba_error('name is required for child nodes') if !name
        if name.is_a?(JabaNode)
          name = name.definition_id
        end
        handle = "#{parent.handle}|#{name}"
        depth = parent.depth + 1
      else
        @services.jaba_error('name not required for root nodes') if name
        depth = 0
        handle = "#{@current_definition.id}"
      end

      @services.log "#{'  ' * depth}Instancing node [type=#{type_id}, handle=#{handle}]"

      if node_from_handle(handle, fail_if_not_found: false)
        @services.jaba_error("Duplicate node handle '#{handle}'")
      end

      jt = if sub_type_id
        @top_level_jaba_type.get_sub_type(sub_type_id)
      else
        @top_level_jaba_type
      end

      jn = JabaNode.new(@services, @current_definition, jt, handle, parent, depth)

      @nodes << jn
      @node_lookup[handle] = jn
      
      begin
        # Give calling block a chance to initialise attributes. This block is in library code as opposed to user
        # definitions so use instance_eval instead of eval_api_block, as it doesn't need to go through api.
        # Read only attributes are allowed to be set (initialised) for the duration of this block.
        #
        if block_given?
          jn.allow_set_read_only_attrs do
            jn.attrs.instance_eval(&block)
          end
        end
        
        # Next execute defaults block if there is one defined for this type.
        #
        defaults = jt.top_level_type.defaults_definition
        if defaults
          jn.eval_api_block(&defaults.block)
        end

        if @current_definition.block
          jn.eval_api_block(&@current_definition.block)
        end
      rescue FrozenError => e
        @services.jaba_error('Cannot modify read only value', callstack: e.backtrace)
      end

      jn.post_create
      jn
    end

    ##
    #
    def node_from_handle(handle, fail_if_not_found: true, callstack: nil)
      n = @node_lookup[handle]
      if !n && fail_if_not_found
        @services.jaba_error("Node with handle '#{handle}' not found", callstack: callstack)
      end
      n
    end

    ##
    # Given a reference attribute and the definition id it is pointing at, returns the node instance.
    #
    def resolve_reference(attr, ref_node_id, ignore_if_same_type: false)
      attr_def = attr.attr_def
      node = attr.node
      rt = attr_def.referenced_type
      rjt = @services.get_top_level_jaba_type(rt) # TOO: improve. Maybe expand referenced_type into a JabaType earlier
      if ignore_if_same_type && rt == node.jaba_type.definition_id
        @reference_attrs_to_resolve << attr
        return ref_node_id
      end
      make_handle_block = attr_def.get_property(:make_handle)
      handle = if make_handle_block
        "#{node.eval_api_block(ref_node_id, &make_handle_block)}"
      else
        "#{ref_node_id}"
      end
      ref_node = rjt.generator.node_from_handle(handle, callstack: attr.last_call_location)
      
      # Don't need to track node references when resolving references between the same types as this
      # happens after all the nodes have been set up, by which time the functionality is not needed.
      # The node references are used in the attribute search path in JabaNode#get_attr.
      #
      if ignore_if_same_type 
        node.add_node_reference(ref_node)
      end
      ref_node
    end

    ##
    # Override this in subclass.
    #
    def init
      # nothing
    end

    ##
    # Override this in sublcass if type needs to be split into more than one node.
    #
    def make_nodes
      make_node
    end
    
    ##
    # Override this in subclass
    #
    def make_projects
    end

    ##
    # Call this from subclass
    #
    def make_project(klass, node, root)
      p = klass.new(@services, self, node, root)
      @node_to_project[node] = p
      p.init
      setup_project(p)
      p
    end
    
    ##
    # Override this in subclass.
    #
    def setup_project(project)
      # Nothing.
    end

    ##
    #
    def project_from_node(node, fail_if_not_found: true)
      p = @node_to_project[node]
      if !p && fail_if_not_found
        @services.jaba_error("'#{node}' not found")
      end
      p
    end
    
    ##
    #
    def perform_generation
      # Call generators defined per-node instance, in the context of the node itself, not its api
      #
      @root_nodes.each do |n|
        # TODO: review again. should it use api?
        n.definition.call_hook(:generate, receiver: n, use_api: false)
      end
      generate
    end

    ##
    # Override this in subclass
    #
    def generate
    end

    ##
    # Override this in subclass.
    #
    def build_jaba_output(g_root, out_dir)
    end

  end
  
  ##
  # The default generator for a JabaType if none exists. Does no generation.
  #
  class DefaultGenerator < Generator
  end

  ##
  # TODO: improve
  class GlobalsGenerator < Generator

    # TODO: extra checking.
    def process
      super
      @services.instance_variable_set(:@globals_node, @root_nodes.first)
    end

  end

end
