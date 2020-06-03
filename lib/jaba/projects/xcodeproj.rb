# frozen_string_literal: true

##
#
module JABA

  using JABACoreExt

  ##
  #
  class XcodeProj < Project
  
    ##
    #
    def init
      @host = @attrs.host_ref
    end

    ##
    #
    def each_config(&block)
      @node.visit_node(type_id: :config, &block)
    end

    ##
    #
    def build_jaba_output(p_root, out_dir)
      p_root[:projroot] = @projroot.relative_path_from(out_dir)
      p_root[:projname] = @projname
      p_root[:host] = @host.definition_id
      p_root[:platform] = @attrs.platform_ref.definition_id
      p_root[:src] = @src.map{|f| f.relative_path_from(out_dir)}
      cfg_root = {}
      p_root[:configs] = cfg_root
      each_config do |c|
        cfg = {}
        attrs = c.attrs
        cfg_root[attrs.config] = cfg
        cfg[:arch] = attrs.arch_ref.definition_id
        cfg[:name] = attrs.config_name
        cfg[:defines] = attrs.defines
        cfg[:inc] = attrs.inc
        cfg[:rtti] = attrs.rtti
      end
    end

  end

end