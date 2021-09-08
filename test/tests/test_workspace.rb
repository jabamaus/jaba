# frozen_string_literal: true

module JABA

  using JABACoreExt

  class TestWorkspace < JabaTest

    it 'matches on id or glob matches' do
      make_file('a/a.cpp', 'b/b.cpp', 'c/d/d.cpp', 'c/e/e.cpp')
      td = temp_dir
      
      op = jaba(cpp_defaults: true, dry_run: true) do
        cpp :a do
          root "#{td}/a"
          project do
            type :app
            src ['.']
          end
        end
        cpp :b do
          root "#{td}/b"
          project do
            type :app
            src ['.']
          end
        end
        cpp :c do
          root "#{td}/c/d"
          project do
            type :app
            src ['.']
          end
        end
        cpp :d do
          root "#{td}/c/e"
          project do
            type :app
            src ['.']
          end
        end
        workspace :w do
          root "#{td}"
          #hosts [:vs2019]
          #platforms [:windows]
          #configs [:Debug, :Release]
          projects [:a, :b, 'c/*']
        end
      end
      proj_a = op[:cpp]['a|windows']
      proj_a.wont_be_nil
      proj_b = op[:cpp]['b|windows']
      proj_b.wont_be_nil
      proj_c = op[:cpp]['c|windows']
      proj_c.wont_be_nil
      proj_d = op[:cpp]['d|windows']
      proj_d.wont_be_nil
      #ws = op[:workspace]['w|windows']
      #ws.wont_be_nil
      #ws.projects.size.must_equal(4)
      #ws.projects[0].id.must_equal(:a)
      #ws.modules[1].id.must_equal(:b)
      #ws.modules[2].id.must_equal(:d)
      #ws.modules[3].id.must_equal(:e)

      assert_jaba_error "Error at #{src_loc(__FILE__, :tagL)}: No projects matching spec 'b' found." do
        jaba do
          workspace :a do
            projects ['b'] # tagL
          end
        end
      end

      # Wildcard matches issue a warning if no projects matched
      #
      assert_jaba_warn "No projects matching spec 'b/**/*' found", __FILE__, 'tagR' do
        jaba(cpp_app: true, dry_run: true) do
          cpp :app do
            project do
              src ['a.cpp'], :force
            end
          end
          workspace :a do
            projects [:app]
            projects ['b/**/*'] # tagR
          end
        end
      end

      # If spec only contains wildcard matches and none match, fail
      #
      assert_jaba_error "Error at #{src_loc(__FILE__, :tagZ)}: No projects matched specs." do
        jaba do
          workspace :a do
            projects ['*', 'b/*'] # tagZ
          end
        end
      end
    end

    it 'only allows valid project types' do
    end
    
    it 'can be specified before containing projects' do
    end

  end

end
