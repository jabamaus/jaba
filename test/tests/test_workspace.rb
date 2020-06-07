# frozen_string_literal: true

module JABA

  using JABACoreExt

  class TestWorkspace < JabaTest

    it 'matches on id or glob matches' do
      make_file('a/a.cpp', 'b/b.cpp', 'c/d/d.cpp', 'c/e/e.cpp')
      td = temp_dir
      
      op = jaba(cpp_defaults: true) do
        cpp :a do
          type :app
          root "#{td}/a"
          src ['.']
        end
        cpp :b do
          type :app
          root "#{td}/b"
          src ['.']
        end
        cpp :c do
          type :app
          root "#{td}/c/d"
          src ['.']
        end
        cpp :d do
          type :app
          root "#{td}/c/e"
          src ['.']
        end
        workspace :w do
          #hosts [:vs2019]
          #platforms [:windows]
          #configs [:Debug, :Release]
          projects [:a, :b, 'c/*']
        end
      end
      proj_a = op[:cpp]['a|vs2019|windows']
      proj_a.wont_be_nil
      proj_b = op[:cpp]['b|vs2019|windows']
      proj_b.wont_be_nil
      proj_c = op[:cpp]['c|vs2019|windows']
      proj_c.wont_be_nil
      proj_d = op[:cpp]['d|vs2019|windows']
      proj_d.wont_be_nil
      #ws = op[:workspace]['w|vs2019|windows']
      #ws.wont_be_nil
      #ws.projects.size.must_equal(4)
      #ws.projects[0].id.must_equal(:a)
      #ws.modules[1].id.must_equal(:b)
      #ws.modules[2].id.must_equal(:d)
      #ws.modules[3].id.must_equal(:e)
    end

    it 'only allows valid project types' do
    end
    
  end

end
