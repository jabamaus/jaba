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
    assert_output 'init|process_definition|generate|build_output' do
      jaba(barebones: true) do
        type :includeBlockTest do
          attr :a
          plugin do
            def init
              print 'init|'
            end
            def process_definition
              print 'process_definition|'
              services.make_node
            end
            def generate
              print 'generate|'
              services.root_nodes[0].attrs.a.must_equal 1
            end
            def build_output(root)
              print 'build_output'
            end
          end
        end
        includeBlockTest :tbt do
          a 1
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
          plugin do
            def init
              print 'init|'
              @projects = []
            end
            def process_definition
              print 'process_definition|'
              root_node = services.make_node
        
              root_node.attrs.platforms.each do |p|
                project = services.make_node(type_id: :project, name: p, parent: root_node, blocks: root_node.attrs.project) do 
                  platform p
                end
                @projects << project
                
                project.attrs.configs.each do |c|
                  services.make_node(type_id: :config, name: c, parent: project, blocks: root_node.attrs.config) do
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
                e.message.must_equal("'t.src' attribute is read only")
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
end
