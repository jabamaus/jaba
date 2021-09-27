module JABA

  class GlobalsPlugin < Plugin

    def process_definition(definition)
      globals_node = services.make_node(definition, flags: NodeFlags::NO_POST_CREATE)
      
      main_services = services.instance_variable_get(:@services)
      main_services.instance_variable_set(:@globals_node, globals_node)
      main_services.instance_variable_set(:@globals, globals_node.attrs)

      main_services.set_global_attrs_from_cmdline

      globals_node.post_create
      globals_node
    end

  end

  ##
  #
  module NodeFlags
    NO_TRACK = 1
    NO_DEFAULTS = 2
    NO_POST_CREATE = 4
    LAZY = 8
    IS_COMPOUND_ATTR = 16
  end

  ##
  #
  class NodeManager
    
    attr_reader :services
    attr_reader :type_id # eg :cpp, :text
    attr_reader :jaba_type
    attr_reader :plugin
    attr_reader :nodes
    attr_reader :root_nodes
    attr_reader :top_level_ids

    ##
    #
    def initialize(services)
      @services = services
      @to_process = []
      @plugin = nil
      @root_nodes = []
      @nodes = [] # all nodes
      @reference_attrs_to_resolve = []
      @pre_processed = false
      @post_processed = false
      @top_level_ids = []
      @compound_attr_creation_params = nil
    end

    ##
    #
    def describe
      "'#{type_id}' node manager"
    end

    ##
    #
    def init(jaba_type, plugin)
      @jaba_type = jaba_type
      @type_id = jaba_type.defn_id
      @plugin = plugin
      @defaults_definition = services.get_definition(:defaults, @type_id, fail_if_not_found: false)
    end

    ##
    #
    CompoundAttrCreationParams = Struct.new(
      :name,
      :parent,
      :block_args,
      :flags,
      :root_node
    )

    ##
    #
    def add_definition(dfn)
      @to_process << dfn
      @top_level_ids << dfn.id
    end

    ##
    #
    def add_compound_attr_definition(dfn, name: nil, parent: nil, block_args: nil, flags: 0)
      cp = CompoundAttrCreationParams.new
      cp.name = name
      cp.parent = parent
      cp.block_args = block_args
      cp.flags = flags
      cp.root_node = nil
      @compound_attr_creation_params = cp
      @to_process << dfn
      cp
    end

    ##
    #
    def process
      services.log "Processing #{describe}", section: true

      if !@pre_processed
        @pre_processed = true
        @plugin.pre_process_definitions
      end

      if @post_processed
        JABA.error("Internal error: #{describe} is being processed after post_process has been called")
      end

      @to_process.each do |definition|
        root_node = @plugin.process_definition(definition)

        if root_node.nil?
          JABA.error("#{type_id} plugin's process_definition() method must return a single node but returned nil")
        end
        if root_node.array?
          JABA.error("#{type_id} plugin's process_definition() method must return a single node but returned an array")
        end
        if root_node != :skip
          @root_nodes << root_node
        end
      end
      @to_process.clear
    end
    
    ##
    #
    def post_process
      @post_processed = true
      
      if @jaba_type.singleton
        if @root_nodes.size == 0
          JABA.error("singleton type '#{type_id}' must be instantiated", errobj: @jaba_type)
        elsif @root_nodes.size > 1
          JABA.error("singleton type '#{type_id}' must only be instantiated once", errobj: @root_nodes.last)
        end
      end

      @reference_attrs_to_resolve.each do |a|
        a.map_value! do |ref|
          resolve_reference(a, ref)
        end
      end

      @root_nodes.sort!{|x, y| x.handle.casecmp(y.handle)}
      @root_nodes.each do |rn|
        rn.make_paths_absolute
      end

      @plugin.post_process_definitions
      
      @nodes.each do |n|
        n.each_attr do |a|
          a.process_flags
        end
        
        n.make_read_only # Make all nodes read only from this point, to help catch mistakes
      end
    end

    ##
    #
    def make_node(
      definition,
      type_id: nil,
      name: nil,
      parent: nil,
      block_args: nil,
      flags: 0,
      blocks: nil,
      &block
    )
      depth = 0
      handle = nil
 
      if @compound_attr_creation_params
        JABA.error("parent should not be set") if parent
        parent = @compound_attr_creation_params.parent
        name = @compound_attr_creation_params.name
        block_args = @compound_attr_creation_params.block_args
        flags |= @compound_attr_creation_params.flags
      end

      if parent
        JABA.error('name is required for child nodes') if !name
        handle = "#{parent.handle}|#{name}"
        depth = parent.depth + 1
      else
        handle = "#{definition.id}"
        handle << "|#{name}" if name
      end

      jt = if type_id
        services.get_jaba_type(type_id)
      else
        @jaba_type
      end

      services.log "#{'  ' * depth}Instancing node [type=#{jt.describe}, handle=#{handle}]"

      jn = JabaNode.new(self, definition.id, definition.src_loc, jt, handle, parent, depth, flags)
      
      if @compound_attr_creation_params
        @compound_attr_creation_params.root_node = jn
        @compound_attr_creation_params = nil
      end

      if flags & NodeFlags::NO_TRACK == 0
        @services.register_node(jn)
        @nodes << jn
      end
      
      begin
        # Give calling block a chance to initialise attributes. This block is in library code as opposed to user
        # definitions so use instance_eval instead of eval_jdl, as it doesn't need to go through api.
        # Read only attributes are allowed to be set (initialised) for the duration of this block.
        #
        if block_given?
          jn.allow_set_read_only_attrs do
            jn.attrs.instance_eval(&block)
          end
        end
        
        if blocks
          Array(blocks).each do |b|
            jn.eval_jdl(&b)
          end
        else
          # Next execute defaults block if there is one defined for this type.
          #
          if flags & NodeFlags::NO_DEFAULTS == 0
            if @defaults_definition
              jn.eval_jdl(&@defaults_definition.block)
            end
          end
 
          if definition.block
            jn.eval_jdl(*block_args, &definition.block)
          end

          definition.open_defs&.each do |d|
            jn.eval_jdl(&d.block)
          end
        end
        
      rescue FrozenError => e
        JABA.error(e.message.sub('frozen', 'read only').capitalize_first, callstack: e.backtrace)
      end

      if flags & NodeFlags::NO_POST_CREATE == 0 # used by globals node when being set from the command line
        jn.post_create
      end

      jn
    end

    ##
    # Given a reference attribute and the definition id it is pointing at, returns the node instance.
    #
    def resolve_reference(attr, ref_node_id, ignore_if_same_type: false)
      attr_def = attr.attr_def
      node = attr.node
      ref_type = attr_def.ref_jaba_type

      if ignore_if_same_type && ref_type == node.jaba_type.defn_id
        @reference_attrs_to_resolve << attr
        return ref_node_id
      end

      make_handle_block = attr_def.make_handle
      handle = if make_handle_block
        "#{node.eval_jdl(ref_node_id, &make_handle_block)}"
      else
        "#{ref_node_id}"
      end

      ref_node = @services.node_from_handle(handle, fail_if_not_found: false)
      if ref_node.nil?
        unresolved_msg_block = attr_def.unresolved_msg
        err_msg = if unresolved_msg_block
          "#{node.eval_jdl(ref_node_id, &unresolved_msg_block)}"
        else
          "Node with handle '#{handle}' not found"
        end
        JABA.error(err_msg, errobj: attr)
      end
      
      # Don't need to track node references when resolving references between the same types as this
      # happens after all the nodes have been set up, by which time the functionality is not needed.
      # The node references are used in the attribute search path in JabaNode#get_attr.
      #
      # TODO: check this. Looks a bit iffy, and definitely confusing
      if ignore_if_same_type
        node.add_node_reference(ref_node)
      end
      ref_node
    end

  end

end
