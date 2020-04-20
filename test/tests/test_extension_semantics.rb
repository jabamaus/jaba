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
      check_fail "'undefined' type not defined", trace: [__FILE__, '# tag1'] do
        jaba do # tag1 TODO: fix error line
          open :undefined do
          end
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

    # TODO: extend
    it 'supports defining new attribute types' do
      check_fail "'b' attribute failed validation: Invalid", trace: [__FILE__, '# tag2A', __FILE__, '# tag2B'] do 
        jaba do
          attr_type :a do
            validate_value do
              fail 'invalid' # tag2A'
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
    
    it 'checks for cyclic dependencies' do
      check_fail '\'a\' contains a cyclic dependency', trace: [__FILE__, '# tag cd'] do
        jaba do # tag cd TODO: fix error location
          define :a do
            dependencies :c
          end
          define :b do
            dependencies :a
          end
          define :c do
            dependencies :b
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
          attr :src
          attr_array :targets do
            flags :required, :unordered
          end
        end

        define :test_target do
          attr :target
          attr :name
        end
        
        test_project :t do
          platforms [:win32, :x64]
          platforms.must_equal [:win32, :x64]
          root 'test'
          targets [:debug, :release]
          case platform
          when :win32
            src 'win32_src'
          when :x64
            src 'x64_src'
          end
          case target
          when :debug
            name "Debug"
          when :release
            name 'Release'
          end
        end
      end
    end

  end

  ##
  #
  class Test_projectGenerator < Generator
    
    ##
    #
    def init
      @projects = []
    end

    ##
    #
    def sub_type(attr_id)
      case attr_id
      when :root, :platforms
        :test_project_root
      end
    end

    ##
    #
    def generate
      @projects.size.must_equal 2

      proj1 = @projects[0]
      proj1.attrs.platform.definition_id.must_equal(:win32)
      proj1.attrs.src.must_equal 'win32_src'
      
      proj2 = @projects[1]
      proj2.attrs.platform.definition_id.must_equal(:x64)
      proj2.attrs.src.must_equal 'x64_src'
    end
    
    ##
    #
    def make_nodes
      root_node = make_node(type_id: :test_project_root, handle: "test_project|root")
      
      root_node.attrs.platforms.each do |p|
        project = make_node(type_id: :test_project, handle: "test_project|root|#{p}", parent: root_node) { platform p }
        @projects << project
        
        project.attrs.targets.each do |t|
          make_node(handle: "test_project|root|#{project.attrs.platform}|target|#{t}", parent: project) { target t }
        end
      end
      root_node
    end
    
  end
  
end
