# frozen_string_literal: true

module JABA

  class TestExtensionSemantics < JabaTest

    it 'supports creating new node types' do
      jaba do
        define :test do
          attr :a do
          end
        end
        test :t do
          a 'b'
          a.must_equal('b')
        end
      end
    end

    it 'fails if try to open undefined type' do
      check_fails("'undefined' has not been defined", trace: [__FILE__, '# tag1']) do
        jaba do
          open :undefined do # tag1
          end
        end
      end
    end
    
    it 'supports adding an attribute to core types' do
      jaba do
        open :workspace do
          attr :a do
          end
        end
        
        workspace :w do
          a 'val'
          a.must_equal('val')
        end
      end
    end

    # TODO: extend
    it 'supports defining new attribute types' do
      check_fails("'b' attribute failed validation: Invalid", trace: [__FILE__, '# tag2A', __FILE__, '# tag2B']) do 
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
      check_fails(/'undefined' attribute type is undefined. Valid types: \[.*?\]/, trace: [__FILE__, '# tag3']) do
        jaba do
          define :a do
            attr :b, type: :undefined do # tag3
            end
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

    it 'supports a generate hook per-object' do
      assert_output 'generate' do
        jaba do
          define :test do
          end
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

          attr_array :platforms do
            flags :unordered, :required
          end
          
          attr :platform do
          end
            
          attr_array :hosts do
            flags :unordered, :required
          end
          
          attr :host do
          end

          attr :src do
          end
          
          attr_array :targets do
            flags :required, :unordered
          end
          
          attr :target do
          end
          
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
            platforms.must_equal [:win32, :x64]
            [:win32, :x64].must_include(platform)
            [:vs2013, :vs2015, :vs2017, :vs2019].must_include(host)
            
            case host
            when :vs2013
              platform.must_equal(:win32)
              rtti&.must_equal('on') # TODO: add assert_property(:rtti, 'on') ?
              src.must_equal 'win32_vs2013_src'
              targets.must_equal [:debug, :release]
            when :vs2015
              platform.must_equal(:win32)
              src.must_equal 'win32_vs2015_src'
              targets.must_equal [:dev, :check]
            when :vs2017
              rtti&.must_equal('off')
              platform.must_equal(:x64)
              src.must_equal 'x64_vs2017_src'
              targets.must_equal [:debug, :release]
            when :vs2019
              platform.must_equal(:x64)
              src.must_equal 'x64_vs2019_src'
              targets.must_equal [:dev, :check]
            end
          end
        end
      end
    end

  end

end
