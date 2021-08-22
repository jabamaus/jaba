# frozen_string_literal: true

##
#
module JABA

  using JABACoreExt
  
  ##
  #
  class NodeManager
    
    attr_reader :services
    attr_reader :type_id # eg :cpp, :text
    attr_reader :jaba_type
    attr_reader :nodes
    attr_reader :root_nodes

    ##
    #
    def initialize(services)
      @services = services
      @definitions = []
      @delay_post_create = false
      @plugin = nil
      @root_nodes = []
      @nodes = [] # all nodes
      @node_lookup = {}
      @reference_attrs_to_resolve = []
    end

    ##
    # Part of internal initialisation.
    #
    def set_jaba_type(tlt)
      @jaba_type = tlt
      @type_id = tlt.defn_id
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
    def process(delay_post_create: false)
      services.log "Processing #{describe}", section: true

      @delay_post_create = delay_post_create
      
      @definitions.each do |d|
        push_definition(d) do
          @root_nodes.concat(Array(@plugin.process_definition(d)))
        end
      end
      
      if @jaba_type.singleton
        if @root_nodes.size == 0
          JABA.error("singleton type '#{type_id}' must be instantiated exactly once", errobj: @jaba_type)
        elsif @root_nodes.size > 1
          JABA.error("singleton type '#{type_id}' must be instantiated exactly once", errobj: @root_nodes.last)
        end
      end

      return if @root_nodes.empty?

      @reference_attrs_to_resolve.each do |a|
        a.map_value! do |ref|
          resolve_reference(a, ref)
        end
      end

      @plugin.make_host_objects
      
      @nodes.each do |n|
        n.each_attr do |a|
          a.process_flags
        end
        
        # Make all nodes read only from this point, to help catch mistakes
        #
        n.make_read_only
      end

      @root_nodes.sort!{|x, y| x.handle.casecmp(y.handle)}
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
    def make_node(child_type_id: nil, name: nil, parent: nil, block_args: nil, &block)
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

      services.log "#{'  ' * depth}Instancing node [type=#{child_type_id}, handle=#{handle}]" # TODO: fix logging of type

      if node_from_handle(handle, fail_if_not_found: false)
        JABA.error("Duplicate node handle '#{handle}'")
      end

      jt = if child_type_id
        @jaba_type.get_child_type(child_type_id)
      else
        @jaba_type
      end

      jn = JabaNode.new(@services, @definition.id, @definition.src_loc, jt, @jaba_type, handle, parent, depth)

      @nodes << jn
      @node_lookup[handle] = jn
      
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
        
        # Next execute defaults block if there is one defined for this type.
        #
        defaults = @jaba_type.defaults_definition
        if defaults
          jn.eval_jdl(&defaults.block)
        end

        if @definition.block
          jn.eval_jdl(*block_args, &@definition.block)
        end

        @definition.open_defs.each do |d|
          jn.eval_jdl(&d.block)
        end
        
      rescue FrozenError => e
        JABA.error('Cannot modify read only value', callstack: e.backtrace)
      end

      if !@delay_post_create # used by globals node when being set from the command line
        jn.post_create
      end

      jn
    end

    ##
    #
    def node_from_handle(handle, fail_if_not_found: true, errobj: nil)
      n = @node_lookup[handle]
      if !n && fail_if_not_found
        JABA.error("Node with handle '#{handle}' not found", errobj: errobj)
      end
      n
    end

    ##
    # Given a reference attribute and the definition id it is pointing at, returns the node instance.
    #
    def resolve_reference(attr, ref_node_id, ignore_if_same_type: false)
      attr_def = attr.attr_def
      node = attr.node
      rt = attr_def.node_type
      rjt = services.get_jaba_type(rt) # TOO: improve. Maybe expand node_type into a JabaType earlier
      if ignore_if_same_type && rt == node.jaba_type.defn_id
        @reference_attrs_to_resolve << attr
        return ref_node_id
      end
      make_handle_block = attr_def.make_handle
      handle = if make_handle_block
        "#{node.eval_jdl(ref_node_id, &make_handle_block)}"
      else
        "#{ref_node_id}"
      end
      ref_node = rjt.node_manager.node_from_handle(handle, fail_if_not_found: false)
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
      if ignore_if_same_type 
        node.add_node_reference(ref_node)
      end
      ref_node
    end

    ##
    #
    def make_node_paths_absolute(node)
      # Turn root into absolute path, if present
      #
      root = node.get_attr(:root, search: true, fail_if_not_found: false)&.map_value! do |r|
        r.absolute_path? ? r : "#{node.source_dir}/#{r}".cleanpath
      end

      # Make all file path attributes (those of type :file, :dir and :src_spec) into absolute paths based on basedir_spec
      #
      node.visit_node(visit_self: true) do |n|
        n.visit_attr(type: [:file, :dir, :src_spec], skip_attr: :root) do |a|
          basedir_spec = a.attr_def.basedir_spec
          base_dir = case basedir_spec
          when :build_root
            services.input.build_root
          when :buildsystem_root
            "#{services.globals.buildsystem_root}"
          when :definition_root
            root
          when :jaba_file
            n.source_dir
          when :cwd
            services.invoking_dir
          else
            JABA.error "Unexpected basedir_spec value '#{basedir_spec}'"
          end

          a.map_value! do |p|
            JABA.spec_to_absolute_path(p, base_dir, n)
          end

          # TODO: this could be done for all attrs not just :file, :dir and :src_spec because in theory other attribute types
          # could have an option of type file/dir/src_spec. They would however need a base_dir_spec option too.
          #
          a.map_value_option! do |id, type, value|
            case type
            when :file, :dir, :src_spec
              JABA.spec_to_absolute_path(value, base_dir, n)
            else
              value
            end
          end
        end
      end
      root
    end
  end

end
