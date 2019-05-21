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

  it 'fails if try to extend undefined type' do
    check_fails("'undefined' has not been defined", trace: [__FILE__, '# tag1']) do
      jaba do
        extend :undefined do # tag1
        end
      end
    end
  end
  
  it 'supports adding an attribute to core types' do
    jaba do
      extend :project do
        attr :a do
        end
      end
      
      project :p do
        platforms [:win32]
        targets [:t]
        a 'val'
        a.must_equal('val')
      end
    end
  end

  # TODO: extend
  it 'supports defining new attribute types' do
    check_fails("'b' attribute failed validation: Invalid", trace: [__FILE__, "raise 'invalid'", __FILE__, '# tag2']) do 
      jaba do
        attr_type :a do
          validate do |val|
            raise 'invalid'
          end
        end
        define :test do
          attr :b, type: :a do
          end
        end
        test :t do
          b 'c' # tag2
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
  
  it 'supports definining new attribute flags' do
    jaba do
      attr_flag :foo
      attr_flag :bar
      
      extend :project do
        attr :a do
          flags :foo, :bar
        end
      end
    end
    # TODO: test something
  end
=begin
  it 'can build a tree of nodes' do
    jaba do
      define :test_project do
        attr :root do
          default '.'
        end

        attr :platforms do
          flags :array, :unordered, :required
        end
        
        attr :platform do
        end
          
        attr :hosts do
        end
        
        attr :host do
        end

        attr :src do
        end
        
        attr :targets do
          flags :array, :required, :unordered
        end
        
        attr :target do
        end
        
        attr :rtti do
        end
    
        build_nodes do
          @project_nodes = []
          root_node = make_node(:root, :platform) # also disable them automatically
          root_node.platforms.each do |p|
            platform_hosts_node = make_node(parent: root_node, platform: p, :hosts)
            platform_hosts_node.hosts.each do |h|
              project_node = make_node(parent: platform_hosts_node, host: h, :src, :targets)
              @project_nodes << project_node
              project_node.targets.each do |t|
                make_node(parent: project_node, target: t, :rti)
              end
            end
          end
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
            src 'x64_vs2015_src'
          end
        when :x64
          hosts [:vs2017, :vs2019]
          if host == :vs2013
            src 'win32_vs2017_src'
          else
            src 'x64_vs2019_src'
          end
        end
        case host
        when :vs2013, :vs2017
          targets [:debug, :release]
        else
          target [:dev, :check]
        end
        
        generate do
        end
      end
    end
  end
=end

end

end
