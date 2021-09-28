class TestExtensionSemantics < JabaTest

  it 'supports creating new node types' do
    jaba(barebones: true) do
      type :test do
        attr :a
      end
      test :t do
        a 'b'
        a.must_equal('b')
      end
    end
  end

  it 'supports opening types and instances' do
    #assert_jaba_error "Error at #{src_loc(__FILE__, :tagL)}: Cannot open undefined type ':undefined'." do
    #  jaba(barebones: true) do
    #    open_type :undefined do # tagL
    #    end
    #  end
    #end
    # TODO: reinstate
=begin
    assert_jaba_error "Error at #{src_loc(__FILE__, :tagN)}: Cannot open undefined instance ':undefined_id'." do
      jaba(barebones: true) do
        open_instance 'undefined_type|undefined_id' do # tagN
        end
      end
    end
    assert_jaba_error "Error at #{src_loc(__FILE__, :tagA)}: Cannot open instance of undefined type ':undefined_id'." do
      jaba(barebones: true) do
        open_instance 'undefined_type|undefined_id' do # tagA
        end
      end
    end
=end
    jaba do
      type :test do
        attr :a do
          default 1
        end
        attr :b
      end
      
      open_type :test do
        attr :c do
          default 3
        end
        attr :d
      end

      open_type :test do
        attr :e do
          default 5
        end
        attr :f
      end

      shared :s do
        b 6
      end

      open_shared :s do
        d 7
      end

      test :t do
        include :s
        a.must_equal(1)
        b.must_equal(6)
        c.must_equal(3)
        d.must_equal(7)
        e.must_equal(5)

        generate do
          attrs.a.must_equal(1)
          attrs.b.must_equal(2) # b changed from 6 to 2 due to instance being opened
          attrs.c.must_equal(3)
          attrs.d.must_equal(4) # d changed from 7 to 4 due to instance being opened
          attrs.e.must_equal(5)
        end
      end

      open_instance 'test|t' do
        b 2
      end
      
      open_instance 'test|t' do
        d 4
      end
    end
  end

  it 'supports defining new attribute types' do
    # TODO
  end
  
  it 'supports defining new attribute flags' do
    # TODO
  end

  it 'supports a generate hook per-definition' do
    assert_output 'generate' do
      jaba(barebones: true) do
        type :test
        test :t do
          generate do
            print 'generate'
          end
        end
      end
    end
  end

  it 'supports defining an inline type plugin' do
    assert_output 'init|init2|pre|pre2|process_twp_top_level|a=1|process2_twp_top_level|process_t|a=2|process2_t|post|post2|generate|generate2|build_output|build_output2' do
      jaba(barebones: true) do
        type :type_with_plugin do
          attr :a
          plugin :type_with_plugin do
            def init
              print 'init|'
            end
            def pre_process_definitions
              print 'pre|'
            end
            def process_definition(definition)
              print "process_#{definition.id}|"
              n = services.make_node(definition)
              print "a=#{n.attrs.a}|"
              n
            end
            def post_process_definitions
              print 'post|'
            end
            def generate
              print 'generate|'
              services.root_nodes[0].attrs.a.must_equal 1
            end
            def build_output(root)
              print 'build_output|'
            end
          end
          plugin :type_with_plugin2 do
            def init
              print 'init2|'
            end
            def pre_process_definitions
              print 'pre2|'
            end
            def process_definition(definition)
              print "process2_#{definition.id}|"
            end
            def post_process_definitions
              print 'post2|'
            end
            def generate
              print 'generate2|'
            end
            def build_output(root)
              print 'build_output2'
            end
          end
        end
        type_with_plugin :twp_top_level do
          a 1
        end
        type :test do
          attr :twp_contained, type: :compound, jaba_type: :type_with_plugin
        end
        test :t do
          twp_contained do
            a 2
          end
        end
      end
    end
  end

  # TODO: beef this up with more features
  it 'can build a tree of nodes' do
    assert_output 'init|process_definition|only called once|generate' do
      jaba do
        type :test_project do
          attr :root do
            default '.'
          end
          attr_array :platforms do
            flags :no_sort, :required
          end
          attr_array :project, type: :block
          attr_array :config, type: :block
          plugin :test_project do
            def init
              print 'init|'
              @projects = []
            end
            def process_definition(definition)
              print 'process_definition|'
              root_node = services.make_node(definition)
        
              root_node.attrs.platforms.each do |p|
                project = services.make_node(definition, type_id: :project, name: p, parent: root_node, blocks: root_node.attrs.project) do 
                  platform p
                end
                @projects << project
                
                project.attrs.configs.each do |c|
                  services.make_node(definition, type_id: :config, name: c, parent: project, blocks: root_node.attrs.config) do
                    config c
                  end
                end
              end
              root_node
            end
            def generate
              print 'generate'
              @projects.size.must_equal 2
        
              proj1 = @projects[0]
              proj1.attrs.platform.defn_id.must_equal(:windows)
              proj1.attrs.src.must_equal 'windows_src'
        
              proj2 = @projects[1]
              proj2.attrs.platform.defn_id.must_equal(:ios)
              proj2.attrs.src.must_equal 'ios_src'
        
              begin
                proj1.attrs.src 'invalid'
              rescue => e
                e.message.must_equal("'t.src' attribute is read only in this context")
              else
                raise 'never get here'
              end
            end
          end
        end
        type :project do
          attr :platform, type: :ref, jaba_type: :platform
          attr :src
          attr_array :configs do
            flags :required, :no_sort
          end
        end
          
        type :config do
          attr :config
          attr :configname
        end

        test_project :t do
          root 'test'
          platforms [:windows, :ios]
          platforms.must_equal [:windows, :ios]
          project do
            configs [:debug, :release]
            src "#{platform.id}_src"
          end
          config do
            case config
            when :debug
              configname "Debug"
            when :release
              configname 'Release'
            end
          end
          generate do
            print 'only called once|'
          end
        end
      end
    end
  end

  it 'can add plugin functionality through on_included' do
    fn = "#{temp_dir}/print_line_plugin.jaba"
    make_file(fn, content: %Q{
type :print_line_plugin do
  attr :line, type: :string
  attr :style, type: :choice do
    items [:upper, :lower]
    default :lower
  end
  plugin :print_line_plugin do
    def process_definition(definition)
      services.make_node(definition)
    end
    def generate
      services.nodes.each do |n|
        str = n.attrs.line
        case n.attrs.style
        when :upper
          str = str.upcase
        when :lower
          str = str.downcase
        end
        print str
      end
    end
  end
end

on_included do |type|
  open_type type do
    attr :print_line, type: :compound, jaba_type: :print_line_plugin
  end
end
    })
    assert_output 'SUCCESS' do
      jaba(barebones: true) do
        include fn, :test
        type :test do
        end
        test :t do
          print_line do
            line 'success'
            style :upper
          end
        end
      end
    end
  end

end
