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
      check_fail "'undefined' type not defined", trace: [__FILE__, 'tagL'] do
        jaba do
          open :undefined do # tagL
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
      check_fail "'b' attribute failed validation: Invalid", trace: [__FILE__, 'tagD', __FILE__, 'tagO'] do 
        jaba do
          attr_type :a do
            validate_value do
              fail 'invalid' # tagD'
            end
          end
          define :test do
            attr :b, type: :a do
            end
          end
          test :t do
            b 'c' # tagO
          end
        end
      end
    end
    
    it 'detects usage of undefined attribute types' do
      check_fail(/'undefined' attribute type is undefined. Valid types: \[.*?\]/, trace: [__FILE__, 'tagK']) do
        jaba do
          define :a do
            attr :b, type: :undefined # tagK
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
      check_fail '\'a\' contains a cyclic dependency', trace: [__FILE__, 'tagF'] do
        jaba do
          define :a do # tagF
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
    
    it 'supports a generate hook per-definition' do
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
      assert_output 'only called once' do
        jaba do
          define :test_project do
            attr :root do
              default '.'
            end
            attr_array :platforms do
              flags :nosort, :required
            end

            define :tproject do
              attr :platform do
                flags :read_only
              end
              attr :platform_ref, type: :reference do
                referenced_type :platform
              end
              attr :src
              attr_array :configs do
                flags :required, :nosort
              end
              
              define :test_config do
                attr :config
                attr :config_name
              end
            end
          end

          test_project :t do
            platforms [:windows]
            platforms.must_equal [:windows]
            root 'test'
            configs [:debug, :release]
            src "#{platform}_src"
            case config
            when :debug
              config_name "Debug"
            when :release
              config_name 'Release'
            end
            generate do
              print 'only called once'
            end
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
    def generate
      @projects.size.must_equal 1

      proj = @projects[0]
      proj.attrs.platform_ref.definition_id.must_equal(:windows)
      proj.attrs.src.must_equal 'windows_src'

      begin
        proj.attrs.src 'invalid'
      rescue JabaDefinitionError => e
        e.raw_message.must_equal("'src' attribute is read only")
      else
        raise 'never get here'
      end
    end
    
    ##
    #
    def make_nodes
      root_node = make_node(type_id: :test_project)
      
      root_node.attrs.platforms.each do |p|
        project = make_node(type_id: :tproject, name: p, parent: root_node) do 
          platform p
          platform_ref p
        end
        @projects << project
        
        project.attrs.configs.each do |c|
          make_node(type_id: :test_config, name: c, parent: project) { config c }
        end
      end
      root_node
    end
    
  end
  
end
