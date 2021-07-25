# frozen_string_literal: true

##
#
module JABA

  using JABACoreExt

  ##
  #
  class Ninjaproj < Project
  
    include SrcFileSupport

    ##
    #
    def initialize(generator, node)
      super
      @projdir = @attrs.projdir
      @projname = @attrs.projname
      @ninja_file = "#{@projdir}/#{@projname}.ninja"
      @host = @attrs.host_ref
    end

    ##
    #
    def post_create
      process_src(:src, :src_ext)
    end

    ##
    #
    def each_config(&block)
      @node.visit_node(type_id: :config, &block)
    end

    ##
    #
    def generate
      services.log "Generating #{@ninja_file}", section: true
      
      file = services.file_manager.new_file(@ninja_file, eol: :native, encoding: 'UTF-8', capacity: 128 * 1024)
      w = file.writer

      @src.each do |sf|
        w << sf.projdir_rel
      end

      file.write
    end

  end

end
