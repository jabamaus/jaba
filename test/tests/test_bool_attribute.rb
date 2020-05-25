# frozen_string_literal: true

module JABA

  class TestBoolAttribute < JabaTest

    it 'defaults to false' do
      jaba do
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
                 trace: [
                   ATTR_TYPES_FILE, 'fail ":bool attributes only accept [true|false]',
                   __FILE__, 'tagP' # evaluated later so exact call line is lost
                 ] do
        jaba do
          define :test do
            attr :b, type: :bool do # tagP
              default 1
            end
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
          b.must_equal(true)
          c.must_equal(false)
        end
      end
    end

    it 'only allows boolean values' do
      check_fail ':bool attributes only accept [true|false]',
                 trace: [
                  ATTR_TYPES_FILE, 'fail ":bool attributes only accept',
                   __FILE__, 'tagW'
                 ] do
        jaba do
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
      check_fail "'a' attribute requires a value", trace: [__FILE__, 'tagY'] do
        jaba do
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
