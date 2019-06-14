# frozen_string_literal: true

module JABA

  class TestExtensionSemantics < JabaTest

    it 'supports creating new node types' do
      jaba do
        define :test do
          attr :a
        end
        test :t do
          a 'b'
          a.must_equal('b')
        end
      end
    end

    it 'fails if try to open undefined type' do
      check_fail "'undefined' has not been defined", trace: [__FILE__, '# tag1'] do
        jaba do
          open :undefined # tag1
        end
      end
    end
    
    it 'supports opening types' do
      jaba do
        open :workspace do
          attr :a
        end
        
        workspace :w do
          a 'val'
          a.must_equal('val')
        end
      end
    end

    it 'supports extending types' do
      jaba do
        define :test do
          attr :a do
            default 1
          end
        end
        define :subtest, extend: :test do
          attr :b do
            default 2
          end
        end
        define :subtest2, extend: :subtest do
          attr :c do
            default 3
          end
        end
        open :test do
          attr :d do
            default 4
          end
        end
            
        subtest2 :s do
          a.must_equal(1)
          b.must_equal(2)
          c.must_equal(3)
          d.must_equal(4)
        end
      end
    end
    
    # TODO: extend
    it 'supports defining new attribute types' do
      check_fail "'b' attribute failed validation: Invalid", trace: [__FILE__, '# tag2A', __FILE__, '# tag2B'] do 
        jaba do
          attr_type :a do
            validate_value do
              raise 'invalid' # tag2A'
            end
          end
          define :test do
            attr :b, type: :a do
            end
          end
          test :t do
            b 'c' # tag2B
          end
        end
      end
    end
    
    it 'detects usage of undefined attribute types' do
      check_fail(/'undefined' attribute type is undefined. Valid types: \[.*?\]/, trace: [__FILE__, '# tag3']) do
        jaba do
          define :a do
            attr :b, type: :undefined # tag3
          end
        end
      end
    end
    
    it 'supports defining new attribute flags' do
      jaba do
        attr_flag :foo
        attr_flag :bar
        
        open :category do
          attr :a do
            flags :foo, :bar
          end
        end
      end
      # TODO: test something
    end

    it 'instances types in order of definition' do
      assert_output 'a;1;2;3;' do
        jaba do
          a :a do
            print '1;'
          end
          a :b do
            print '2;'
          end
          a :c do
            print '3;'
          end
          define :a do
            print 'a;'
          end
        end
      end
    end
    
    it 'supports dependencies between types' do
      assert_output 'def a;def b;def c;a;b;c;' do
        jaba do
          define :a do
            print 'def a;'
          end
          define :b do
            print 'def b;'
            dependencies [:a]
          end
          define :c do
            dependencies [:b]
            print 'def c;'
          end
          c :c do
            print 'c;' # evaluated third
          end
          a :a do
            print 'a;' # evaluated first
          end
          b :b do
            print 'b;' # evaluated second
          end
        end
      end
    end
    
    it 'supports a generate hook per-object' do
      assert_output 'generate' do
        jaba do
          define :test
          test :t do
            generate do
              print 'generate'
            end
          end
        end
      end
    end
    
    it 'can build a tree of nodes' do
      jaba do
        define :test_project do
          attr :root do
            default '.'
          end

          attr_array :platforms, type: :reference do
            referenced_type :platform
            flags :unordered, :required
          end
          
          attr :platform
            
          attr_array :hosts, type: :reference do
            referenced_type :host
            flags :unordered, :required
          end
          
          attr :host
          attr :src
          
          attr_array :targets do
            flags :required, :unordered
          end
          
          attr :target
          
          attr :rtti do
            default do
              case platform
              when :win32
                default 'on'
              when :x64
                default 'off'
              end
            end
          end
      
          build_nodes do
            project_nodes = []
            root_node = make_node(attrs_mask: [:root, :platforms])
            root_node.platforms.each do |p|
              platform_hosts_node = make_node(parent: root_node, attrs_mask: [:platform, :hosts]) {|n| n.platform p}
              platform_hosts_node.hosts.each do |h|
                project_node = make_node(parent: platform_hosts_node, attrs_mask: [:host, :src, :targets]) {|n| n.host h}
                project_nodes << project_node
                project_node.targets.each do |t|
                  make_node(parent: project_node, attrs_mask: [:target, :rtti]) {|n| n.target t}
                end
              end
            end
            project_nodes
          end
        end
        
        test_project :t do
          platforms [:win32, :x64]
          platforms.must_equal [:win32, :x64]
          root 'test'
          case platform
          when :win32
            hosts [:vs2013, :vs2015]
            if host == :vs2013
              src 'win32_vs2013_src'
            else
              src 'win32_vs2015_src'
            end
          when :x64
            hosts [:vs2017, :vs2019]
            if host == :vs2017
              src 'x64_vs2017_src'
            else
              src 'x64_vs2019_src'
            end
          end
          case host
          when :vs2013, :vs2017
            targets [:debug, :release]
          else
            targets [:dev, :check]
          end
          
          generate do
            platforms[0].id.must_equal(:win32)
            platforms[1].id.must_equal(:x64)
            
            case host.id
            when :vs2013
              platform.id.must_equal(:win32)
              rtti&.must_equal('on')
              src.must_equal 'win32_vs2013_src'
              targets.must_equal [:debug, :release]
            when :vs2015
              platform.id.must_equal(:win32)
              src.must_equal 'win32_vs2015_src'
              targets.must_equal [:dev, :check]
            when :vs2017
              rtti&.must_equal('off')
              platform.id.must_equal(:x64)
              src.must_equal 'x64_vs2017_src'
              targets.must_equal [:debug, :release]
            when :vs2019
              platform.id.must_equal(:x64)
              src.must_equal 'x64_vs2019_src'
              targets.must_equal [:dev, :check]
            end
          end
        end
      end
    end

  end

end
