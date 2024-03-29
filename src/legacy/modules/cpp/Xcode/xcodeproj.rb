module JABA

  class Xcodeproj
    include SrcFileSupport
    
    attr_reader :services
    attr_reader :attrs

    def initialize(plugin, node)
      @plugin = plugin
      @node = node
      @attrs = node.attrs
      @projdir = @attrs.projdir
      @projname = @attrs.projname
      @host = @attrs.host
      @root = @attrs.root
    end

    def handle = @node.handle
    def post_create = process_src(:src, :src_ext, :src_exclude)
    def generate ; end
    
    def each_config(&block)
      @node.visit_node(type_id: :config, &block)
    end

    def build_output(p_root)
      p_root[:projdir] = @projdir
      p_root[:projname] = @projname
      p_root[:host] = @host.defn_id
      p_root[:platform] = @attrs.platform.defn_id
      p_root[:src] = @src.map{|f| f.absolute_path}
      cfg_root = {}
      p_root[:configs] = cfg_root
      each_config do |c|
        cfg = {}
        attrs = c.attrs
        cfg_root[attrs.config] = cfg
        cfg[:arch] = attrs.arch.defn_id
        cfg[:name] = attrs.configname
        cfg[:define] = attrs.define
        cfg[:inc] = attrs.inc
        cfg[:rtti] = attrs.rtti
      end
    end
  end
end
