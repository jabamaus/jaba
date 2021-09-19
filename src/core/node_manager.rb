module JABA

  class GlobalsPlugin < Plugin

    def process_definition
      globals_node = services.make_node(flags: NodeFlags::NO_POST_CREATE)
      
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
    attr_reader :definition # current definition being processed

    ##
    #
    def initialize(services)
      @services = services
      @definitions = []
      @plugin = nil
      @root_nodes = []
      @nodes = [] # all nodes
      @reference_attrs_to_resolve = []
    end

    ##
    # Part of internal initialisation.
    #
    def init(jt)
      @jaba_type = jt
      @type_id = jt.defn_id
      @defaults_definition = services.get_definition(:defaults, @type_id, fail_if_not_found: false)
    end

    ##
    # Part of internal initialisation.
    #
    def register_instance_definition(d)
      @definitions << d
    end

    ##
    #
    def describe
      "'#{type_id}' node manager"
    end

    ##
    #
    def process
      services.log "Processing #{describe}", section: true

      # Give plugin a chance to do some initialisation before nodes are created. Dependent plugins that have already
      # been processed can be accessed here.
      #
      @plugin.pre_process_definitions

      @definitions.each do |d|
        push_definition(d) do
          root_nodes = Array(@plugin.process_definition)
          @root_nodes.concat(root_nodes)
        end
      end
      
      if @jaba_type.singleton
        if @root_nodes.size == 0
          JABA.error("singleton type '#{type_id}' must be instantiated", errobj: @jaba_type)
        elsif @root_nodes.size > 1
          JABA.error("singleton type '#{type_id}' must only be instantiated once", errobj: @root_nodes.last)
        end
      end

      return if @root_nodes.empty?

      @reference_attrs_to_resolve.each do |a|
        a.map_value! do |ref|
          resolve_reference(a, ref)
        end
      end

      @root_nodes.each do |rn|
        rn.make_paths_absolute
      end

      @root_nodes.sort!{|x, y| x.handle.casecmp(y.handle)}

      @plugin.post_process_definitions
      
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
    def push_definition(d)
      @definition = d
      yield
      @definition = nil
    end

    ##
    #
    def make_node(
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
 
      if parent
        JABA.error('name is required for child nodes') if !name
        handle = "#{parent.handle}|#{name}"
        depth = parent.depth + 1
      else
        handle = "#{@definition.id}"
        handle << "|#{name}" if name
      end

      services.log "#{'  ' * depth}Instancing node [type=#{type_id}, handle=#{handle}]" # TODO: fix logging of type

      jt = if type_id
        services.get_jaba_type(type_id)
      else
        @jaba_type
      end

      jn = JabaNode.new(self, @definition.id, @definition.src_loc, jt, handle, parent, depth, flags)

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
 
          if @definition.block
            jn.eval_jdl(*block_args, &@definition.block)
          end

          @definition.open_defs&.each do |d|
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
