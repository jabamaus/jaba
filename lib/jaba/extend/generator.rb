# frozen_string_literal: true

##
#
module JABA

  using JABACoreExt
  
  ##
  # TODO: split this. Not nice having internal code mixed with generator code.
  #
  class Generator
    
    # Define wrappers so that Generator subclass can work with the kind of objects it wants and not have to
    # call everything a 'host_object' which would get very confusing. Using :project here would be very 
    # common but the WorkspaceGenerator uses :workspace, for example.
    #
    def self.work_with(type)
      class_eval %Q{
        def make_#{type}(...)
          make_host_object(...)
        end
        def #{type}_from_node(...)
          host_object_from_node(...)
        end
        def each_#{type}(&block)
          @host_objects.each(&block)
        end
        def get_#{type}s
          @host_objects
        end
      }, __FILE__, __LINE__
    end

    attr_reader :services
    attr_reader :type_id # eg :cpp, :text
    attr_reader :top_level_jaba_type
    attr_reader :root_nodes

    ##
    #
    def initialize(services)
      @services = services
      @definitions = []
      @root_nodes = []
      @nodes = []
      @node_lookup = {}
      @host_objects = []
      @node_to_host_object = {}
      @reference_attrs_to_resolve = []
    end

    ##
    #
    def set_top_level_type(tlt)
      @top_level_jaba_type = tlt
      @type_id = tlt.defn_id
    end

    ##
    #
    def describe
      "'#{@type_id}' generator"
    end

    ##
    #
    def process
      services.log "Processing #{describe}", section: true

      @definitions.each do |d|
        push_definition(d) do
          @root_nodes << make_nodes
        end
      end
      
      if @top_level_jaba_type.singleton
        if @root_nodes.size == 0
          JABA.error("singleton type '#{type_id}' must be instantiated exactly once", errobj: @top_level_jaba_type)
        elsif @root_nodes.size > 1
          JABA.error("singleton type '#{type_id}' must be instantiated exactly once", errobj: @root_nodes.last)
        end
      end

      @reference_attrs_to_resolve.each do |a|
        a.map_value! do |ref|
          resolve_reference(a, ref)
        end
      end

      make_host_objects
      
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
    def register_instance_definition(d)
      @definitions << d
    end

    ##
    #
    def get_generator(top_level_type_id)
      services.get_generator(top_level_type_id)
    end

    ##
    #
    def register_cmdline_cmd(opt, **args)
      services.input_manager.register_cmd(opt, **args)
    end

    ##
    #
    def register_cmdline_option(opt, **args)
      services.input_manager.register_option(opt, phase: 2, **args)
    end

    ##
    #
    def push_definition(d)
      @definition = d
      yield
      @definition = nil
    end

    ##
    # Call this from subclass
    #
    def make_node(sub_type_id: nil, name: nil, parent: nil, block_args: nil, &block)
      depth = 0
      handle = nil

      if parent
        JABA.error('name is required for child nodes') if !name
        if name.is_a?(JabaNode)
          name = name.defn_id
        end
        handle = "#{parent.handle}|#{name}"
        depth = parent.depth + 1
      else
        JABA.error('name not required for root nodes') if name
        handle = "#{@definition.id}"
      end

      services.log "#{'  ' * depth}Instancing node [type=#{type_id}, handle=#{handle}]"

      if node_from_handle(handle, fail_if_not_found: false)
        JABA.error("Duplicate node handle '#{handle}'")
      end

      jt = if sub_type_id
        @top_level_jaba_type.get_sub_type(sub_type_id)
      else
        @top_level_jaba_type
      end

      jn = JabaNode.new(@services, @definition.id, @definition.src_loc, jt, handle, parent, depth)

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
        defaults = jt.top_level_type.defaults_definition
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

      jn.post_create
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
      rjt = services.get_top_level_jaba_type(rt) # TOO: improve. Maybe expand node_type into a JabaType earlier
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
      ref_node = rjt.generator.node_from_handle(handle, errobj: attr)
      
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
    def jaba_warn(...)
      services.jaba_warn(...)
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
    def make_host_objects
    end

    ##
    # Call this from subclass but using the wrapper defined by Generator.work_with.
    #
    def make_host_object(klass, node, *args, **keyval_args)
      klass = klass.string? ? JABA.const_get(klass) : klass
      ho = klass.new(self, node, *args, **keyval_args)
      @host_objects << ho
      @node_to_host_object[node] = ho
      ho
    end

    ##
    #
    def host_object_from_node(node, fail_if_not_found: true)
      ho = @node_to_host_object[node]
      if !ho && fail_if_not_found
        JABA.error("'#{ho}' not found")
      end
      ho
    end
    
    ##
    #
    def make_node_paths_absolute(node)
      # Turn root into absolute path, if present
      #
      root = node.get_attr(:root, search: true, fail_if_not_found: false)&.map_value! do |r|
        r.absolute_path? ? r : "#{node.source_dir}/#{r}".cleanpath
      end

      # Make all :file and :dir attributes into absolute paths based on basedir_spec
      #
      node.visit_node(visit_self: true) do |n|
        n.visit_attr(type: [:file, :dir], skip_attr: :root) do |a|
          basedir_spec = a.attr_def.basedir_spec
          base_dir = case basedir_spec
          when :build_root
            services.input.dest_root
          when :definition_root
            root
          when :jaba_file
            n.source_dir
          when :cwd
            JABA.invoking_dir
          else
            JABA.error "Unexpected basedir_spec value '#{basedir_spec}'"
          end

          a.map_value! do |p|
            JABA.spec_to_absolute_path(p, base_dir, n)
          end
        end
      end
      root
    end
    
    ##
    #
    def perform_generation
      # Call generators defined per-node instance, in the context of the node itself, not its api
      #
      @root_nodes.each do |n|
        n.call_hook(:generate, receiver: n, use_api: false)
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

    def make_host_objects
      @root_nodes.each do |n|
        make_node_paths_absolute(n)
      end
    end
  end

end
