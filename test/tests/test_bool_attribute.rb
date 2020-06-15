# frozen_string_literal: true

module JABA

  class TestBoolAttribute < JabaTest

    it 'defaults to false' do
      jaba(barebones: true) do
        define :test do
          attr :a, type: :bool
        end
        test :t do
          a.must_equal(false)
        end
      end
    end

    it 'requires default to be true or false' do
      check_fail ':bool attributes only accept [true|false] but got \'1\'',
                 line: [ATTR_TYPES_JDL, 'fail ":bool attributes only accept [true|false]'],
                 trace: [__FILE__, 'tagP'] do # evaluated later so exact call line is lost
        jaba(barebones: true) do
          define :test do
            attr :b, type: :bool do # tagP
              default 1
            end
          end
        end
      end
      jaba(barebones: true) do
        define :test do
          attr :b, type: :bool do
            default true
          end
          attr :c, type: :bool do
            default false
          end
        end
        test :t do
          b.must_equal(true)
          c.must_equal(false)
        end
      end
    end

    it 'only allows boolean values' do
      check_fail ':bool attributes only accept [true|false]',
                 line: [ATTR_TYPES_JDL, 'fail ":bool attributes only accept'], trace: [__FILE__, 'tagW'] do
        jaba(barebones: true) do
          define :test do
            attr :c, type: :bool do
              default true
            end
          end
          test :b do
            c 1 # tagW
          end
        end
      end
      jaba do
        define :test do
          attr :b, type: :bool do
            default true
          end
          attr :c, type: :bool do
            default false
          end
        end
        test :t do
          b false
          c true
          b.must_equal(false)
          c.must_equal(true)
        end
      end
    end
    
    it 'works with :required flag' do
      check_fail "'t::a' attribute requires a value", line: [__FILE__, 'tagY'] do
        jaba(barebones: true) do
          define :test do
            attr :a, type: :bool do
              flags :required
            end
          end
          test :t do # tagY
          end
        end
      end
    end

  end

end
