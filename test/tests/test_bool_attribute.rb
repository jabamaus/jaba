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

    it 'requires a default of true or false' do
      check_fail ':bool attributes only accept [true|false]',
                 trace: [
                   ATTR_TYPES_FILE, "fail ':bool attributes only accept [true|false]'",
                   __FILE__, '# tag1' # evaluated later so exact call line is lost
                 ] do
        jaba do
          define :test do
            attr :b, type: :bool do # tag1
              default 1
            end
          end
        end
      end
    end

    it 'only allows boolean values' do
      check_fail ':bool attributes only accept [true|false]',
                 trace: [
                  ATTR_TYPES_FILE, "fail ':bool attributes only accept [true|false]'",
                   __FILE__, '# tag2'
                 ] do
        jaba do
          define :test do
            attr :c, type: :bool do
              default true
            end
          end
          test :b do
            c 1 # tag2
          end
        end
      end
    end
    
  end

end
