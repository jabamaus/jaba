# frozen_string_literal: true

module JABA

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
      check_fail "'undefined' type not defined", line: [__FILE__, 'tagL'] do
        jaba(barebones: true) do
          open_type :undefined do # tagL
          end
        end
      end
      # TODO: also check type
      check_fail "'undefined_id' instance not defined", line: [__FILE__, 'tagA'] do
        jaba(barebones: true) do
          open_instance :undefined_id, type: :undefined_type do # tagA
          end
        end
      end
      # TODO: test opening sub types
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

        open_instance :t, type: :test do
          b 2
        end
        
        open_instance :t, type: :test do
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

    it 'supports dependencies between types' do
      assert_output 'def a;def b;def c;a;b;c;' do
        jaba(barebones: true) do
          type :a do
            print 'def a;'
          end
          type :b do
            print 'def b;'
            dependencies [:a]
          end
          type :c do
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
      check_fail '\'a\' type contains a cyclic dependency', line: [__FILE__, 'tagF'] do
        jaba(barebones: true) do
          type :a do # tagF
            dependencies :c
          end
          type :b do
            dependencies :a
          end
          type :c do
            dependencies :b
          end
        end
      end
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
    
    it 'can build a tree of nodes' do
      assert_output 'only called once' do
        jaba do
          type :test_project do
            attr :root do
              default '.'
            end
            attr_array :platforms do
              flags :no_sort, :required
            end
            type :project do
              attr :platform do
                flags :read_only
              end
              attr :platform_ref, type: :node_ref do
                node_type :platform
              end
              attr :src
              attr_array :configs do
                flags :required, :no_sort
              end
            end
              
            type :config do
              attr :config
              attr :configname
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
              configname "Debug"
            when :release
              configname 'Release'
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
    def initialize(services)
      super
      @projects = []
    end

    ##
    #
    def generate
      @projects.size.must_equal 1

      proj = @projects[0]
      proj.attrs.platform_ref.defn_id.must_equal(:windows)
      proj.attrs.src.must_equal 'windows_src'

      begin
        proj.attrs.src 'invalid'
      rescue => e
        e.message.must_equal("'t.src' attribute is read only")
      else
        raise 'never get here'
      end
    end
    
    ##
    #
    def process_definition
      root_node = make_node
      
      root_node.attrs.platforms.each do |p|
        project = make_node(sub_type_id: :project, name: p, parent: root_node) do 
          platform p
          platform_ref p
        end
        @projects << project
        
        project.attrs.configs.each do |c|
          make_node(sub_type_id: :config, name: c, parent: project) { config c }
        end
      end
      root_node
    end
    
  end
  
end
