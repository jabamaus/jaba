jtest "array supports a default" do
  jdl do
    # Validates default is an array
    JTest.assert_jaba_error "Error at #{JTest.src_loc("C3E1CABD")}: 'a' attribute invalid - 'default' expects an array but got '{:a=>:b}'." do
      attr :a, variant: :array do
        default({ a: :b }) # C3E1CABD
      end
    end

    # Validates default elements respect attribute type
    JTest.assert_jaba_error "Error at #{JTest.src_loc("7F5657F4")}: 'b' attribute invalid - 'default' invalid - 'not a bool' is a string - expected [true|false]" do
      attr :b, variant: :array, type: :bool do
        default ["not a bool"] # 7F5657F4
      end
    end
  end
  jaba do end

  jdl do
    attr :c, variant: :array do
      default do # 9F62104F
        1
      end
    end
  end
  # Have to put this round the whole jaba context because the default block is called twice, once when it is called explicitly
  # and again by jaba itself when the value is baked in
  assert_jaba_error "Error at #{src_loc("9F62104F")}: 'c' attribute 'default' invalid - expects an array but got '1'." do
    jaba do
      c # Validates default is an array when block form is called explicity
    end
  end

  jdl do
    attr :d, variant: :array do
      default 1 # 1E5D0C2E
    end
  end
  assert_jaba_error "Error at #{src_loc("1E5D0C2E")}: 'd' attribute invalid - 'default' expects an array but got '1'." do
    jaba do end # It validates default is an array when value form is called implicitly
  end

  jdl do
    attr :d, variant: :array, type: :bool do # 33EF0612
      default do
        ["not a bool"] # Validates default elements respect attribute type when block form used
      end
    end
  end

  assert_jaba_error "Error at #{src_loc("33EF0612")}: 'd' attribute 'default' invalid - 'not a bool' is a string - expected [true|false]" do
    jaba do
      d
    end
  end

  jdl do
    attr :a, variant: :array, type: :int
    attr :b, variant: :array, type: :int do
      default [1, 2, 3] # value style default
    end
    attr :c, variant: :array, type: :int do
      default do # block style default
        [4, 5, 6]
      end
    end
    attr :d, variant: :array, type: :int do
      default do # block style default referencing other attrs
        b + c
      end
    end
    attr :e, variant: :array, type: :int do
      default [7, 8]
    end
    attr :f, variant: :array, type: :int do
      default [9]
      flags :overwrite_default
    end
    attr :g, variant: :array, type: :int do
      default [11]
      flags :overwrite_default
    end
  end

  op = jaba do
    a.must_equal [] # defaults to empty array
    b.must_equal [1, 2, 3]
    c.must_equal [4, 5, 6]
    d.must_equal [1, 2, 3, 4, 5, 6]
    d [7, 8] # default array values are appended to not overwritten when block style used
    d 9
    d.must_equal [1, 2, 3, 4, 5, 6, 7, 8, 9]
    e [9] # default array values are appended to not overwritten when value style used
    e.must_equal [7, 8, 9]
    f.must_equal [9]
    f 10 # default will be overwritten not appended to due to :overwrite_default flag
    f.must_equal [10]
    g.must_equal [11] # Don't overwrite g, check that it still has default value when jaba completes
  end
  r = op[:root]
  r[:a].must_equal []
  r[:b].must_equal [1, 2, 3]
  r[:c].must_equal [4, 5, 6]
  r[:d].must_equal [1, 2, 3, 4, 5, 6, 7, 8, 9]
  r[:e].must_equal [7, 8, 9]
  r[:f].must_equal [10]
  r[:g].must_equal [11]
end

jtest "checks for accessing uninitialised attributes" do
  jdl do
    attr :a
    attr :b
    attr :c, variant: :array do
      default do
        [a, b]
      end
    end
  end

  # test with array attr default using an unset attr
  assert_jaba_error "Error at #{src_loc("9BCB5240")}: 'c' attribute default read uninitialised 'b' attribute - it might need a default value." do
    jaba do
      a 1
      c # 9BCB5240
    end
  end

  jdl do
    attr :a, variant: :array
    attr :b do
      default do
        a[0]
      end
    end
  end

  # test with another attr using unset array attr
  assert_jaba_error "Error at #{src_loc("49323AB4")}: 'b' attribute default read uninitialised 'a' attribute - it might need a default value." do
    jaba do
      b # 49323AB4
    end
  end
end

jtest "allows setting value with block" do
  jdl do
    attr :a, variant: :array
    attr :b
    attr :c
    attr :d
  end
  jaba do
    b 1
    c 2
    d 3
    a do
      val = []
      val << b if b < 2
      val << c if c > 3
      val << d if d == 3
      val
    end
    a.must_equal [1, 3]
  end
end

jtest "is not possible to modify returned array" do
  jdl do
    attr :a, variant: :array do
      default [1]
    end
    attr :b, variant: :array do
      default do
        [2]
      end
    end
  end
  assert_jaba_error "Error at #{src_loc("B50C68BE")}: Can't modify read only Array." do
    jaba do
      a << 3 # B50C68BE
    end
  end
  assert_jaba_error "Error at #{src_loc("EFB142BD")}: Can't modify read only Array." do
    jaba do
      b << 4 # EFB142BD
    end
  end
  assert_jaba_error "Error at #{src_loc("4BE55ADE")}: Can't modify read only Array." do
    jaba do
      b[0] = 5 # 4BE55ADE
    end
  end
end

jtest "handles duplicates" do
  jdl do
    attr :a, variant: :array # Duplicates will be stripped by default
    attr :b, variant: :array do
      flags :allow_dupes
    end
    attr :c, variant: :array, type: :bool
    attr :d, variant: :array
  end
  op = jaba do
    a [5, 6, 6, 7, 7, 7, 8] # DD827579
    a.must_equal [5, 6, 7, 8]
    b [5, 5, 6, 6, 7, 7, 7] # duplicates allowed
    b.must_equal [5, 5, 6, 6, 7, 7, 7]
    c [true, false, false, true] # Never strips duplicates in bool arrays
    c.must_equal [true, false, false, true]
    d ["aa", "ab", "ac"] # 3A77A0E4
    d ["a", "b", "c"], prefix: "a" # A34DE72A Test duplicates caused by prefix still stripped
    d.must_equal ["aa", "ab", "ac"]
  end
  w = op[:warnings]
  w.size.must_equal 2
  # Previous duplicate location only reported if on different line
  w[0].must_equal "Warning at #{src_loc("DD827579")}: [6, 7, 7] dupes stripped from 'a' attribute."
  w[1].must_equal "Warning at #{src_loc("A34DE72A")}: [\"aa\", \"ab\", \"ac\"] dupes stripped from 'd' attribute. See previous at test_attribute_array.rb:#{src_line("3A77A0E4")}."
end

jtest "handles sorting" do
  jdl do
    attr :a, variant: :array
    attr :b, variant: :array, type: :string do
      flags :allow_dupes
    end
    attr :c, variant: :array
    attr :d, variant: :array, type: :string do
      flags :allow_dupes
    end
    attr :e, variant: :array, type: :bool
    attr :f, variant: :array do
      flags :no_sort
    end
  end
  op = jaba do
    a [5, 4, 2, 1, 3]
    a.must_equal [5, 4, 2, 1, 3] # doesn't sort immediately
    b ["e", "c", :a, "a", "A", :C] # sorts case-insensitively
    c [10.34, 3, 800.1, 0.01, -1]
    d [:e, :c, :a, :A, :C]
    e [true, false, false, true] # never sorts a bool array
    f [5, 4, 3, 2, 1]
  end
  r = op[:root]
  r[:a].must_equal [1, 2, 3, 4, 5]
  r[:b].must_equal [:a, "a", "A", "c", :C, "e"]
  r[:c].must_equal [-1, 0.01, 3, 10.34, 800.1]
  r[:d].must_equal [:a, :A, :c, :C, :e]
  r[:e].must_equal [true, false, false, true]
  r[:f].must_equal [5, 4, 3, 2, 1] # unsorted due to :no_sort
end

jtest "validates element types are valid" do
  jdl do
    attr :a, variant: :array, type: :bool
  end
  assert_jaba_error "Error at #{src_loc("F18B556A")}: 'a' attribute invalid - 'true' is a string - expected [true|false]" do
    jaba do
      a [true, false, false, true]
      a ["true"] # F18B556A
    end
  end
end

jtest "supports prefix and postfix options" do
  jdl do
    attr :a, variant: :array do
      flags :no_sort, :allow_dupes
    end
    attr :b, variant: :array do
      default ["a"]
    end
  end
  jaba do
    a ["j", "a", "b", "a"], prefix: "1", postfix: "z"
    a.must_equal ["1jz", "1az", "1bz", "1az"]
    b ["c"], prefix: "1", postfix: "z" # doesn't apply to default value
    b.must_equal ["a", "1cz"]

    JTest.assert_jaba_error "Error at #{JTest.src_loc("DBBF56B8")}: [prefix|postfix] can only be applied to string values." do
      b [1, 2, 3], prefix: "a" # DBBF56B8
    end
    JTest.assert_jaba_error "Error at #{JTest.src_loc("C27E4668")}: [prefix|postfix] can only be applied to string values." do
      b [1, 2, 3], postfix: "b" # C27E4668
    end
  end
end

jtest "supports immediately deleting elements" do
  jdl do
    attr :a, variant: :array, type: :int
    attr :b, variant: :array, type: :string
  end
  jaba do
    a [1, 2, 3, 4]
    a delete: [2, 3]
    a.must_equal [1, 4]
    a delete: 1
    a delete: 4
    a.must_equal []

    b ["a", "b"], delete: ["a", "b"]
    b.must_equal []
    b ["c", "d", "e"]
    b delete: "d"
    b delete: "e"
    b.must_equal ["c"]
    b delete: "c"
    b.must_equal []

    # Delete works with attributes that map values, eg string attribute maps symbols to strings
    #
    b [:a, :b], delete: [:a, :b]
    b.must_equal []
    b [:c, :d, :e]
    b delete: :d
    b delete: :e
    b.must_equal ["c"]
    b delete: :c
    b.must_equal []

    # delete works with prefix and postfix options
    #
    b ["abc", "acc", "adc", "aec"]
    b delete: ["c", "d"], prefix: "a", postfix: "c"
    b.must_equal ["abc", "aec"]
    b delete: ["abc", "aec"]
    b.must_equal []

    # delete works with regexes
    #
    b ["one", "two", "three", "four"]
    b delete: [/o/, "three"]
    b.must_equal []

    b [:one, :two, :three, :four]
    b delete: [/o/, :three]
    b.must_equal []

    # deletion can be conditional
    #
    b ["a", "b", "c", "d", "e"]
    b delete: ->(e) { (e == "d") || (e == "c") }
    b.must_equal ["a", "b", "e"]
    b delete: ->(e) { true }
    b.must_equal []
    a [1, 2, 3, 4], delete: ->(e) { e > 2 }
    a.must_equal [1, 2]
  end
end

jtest "fails if deleting with regex on non-strings" do
  jdl do
    attr :a, variant: :array
  end
  jaba do
    JTest.assert_jaba_error "Error at #{JTest.src_loc("2CC0D619")}: delete with a regex can only operate on strings or symbols." do
      a [1, 2, 3, 4, 43], delete: [/3/] # 2CC0D619
    end
  end
end

jtest "warns if nothing deleted" do
  jdl do
    attr :a, variant: :array
  end
  op = jaba do
    a [1, 2, 3, 4, 43], delete: [7, 8] # D5F5139A
  end
  w = op[:warnings]
  w.size.must_equal 1
  w[0].must_equal "Warning at #{src_loc("D5F5139A")}: no elements deleted."
end

jtest "supports excluding elements" do
  # TODO
end

jtest "supports flag options" do
  jdl do
    attr :a, variant: :array do
      flag_option :a
      flag_option :b
      flag_option :c
      flags :allow_dupes
    end
    attr :b, variant: :array do
      flag_option :a
      flag_option :b
      flag_option :c
    end
  end
  op = jaba do
    JTest.assert_jaba_error "Error at #{JTest.src_loc("0BE71C6C")}: 'a' attribute does not support ':d' flag option. Valid flags are [:a, :b, :c]" do
      a 1, :d # 0BE71C6C
    end
    # because :allow_dupes is specified these will all be separate elements
    a 1, :a
    a 1, :a
    a 2, :b

    # b does not allow dupes so flags will be merged. A duplicate warning will only issued if value and flags are the same
    b 1, :a
    b 1, :b # D9F57A3F
    b 1 # CD7C1057 duplicate warning issued and will be a noop
    b 1, :b # 0606C35D duplicate flag warning issued
  end
  op[:warnings].must_equal [
    "Warning at #{src_loc("CD7C1057")}: [1] dupes stripped from 'b' attribute. See previous at #{src_loc("D9F57A3F")}.",
    "Warning at #{src_loc("0606C35D")}: 'b' attribute was passed duplicate flag ':b'.",
  ]
  a = op[:root].get_attr(:a)
  a.value.must_equal [1, 1, 2]
  a[0].flag_options.must_equal [:a]
  a[1].flag_options.must_equal [:a]
  a[2].flag_options.must_equal [:b]

  b = op[:root].get_attr(:b)
  b.value.must_equal [1]
  b[0].flag_options.must_equal [:a, :b]
end

jtest "supports value options" do
  jdl do
    attr :a, variant: :array do
      flags :allow_dupes
      option :opt_single, type: :int
      option :opt_array, variant: :array
      option :opt_single_choice, type: :choice do
        items [:a, :b, :c]
      end
    end
    attr :b, variant: :array do # dupes will be stripped
      option :opt_single, type: :int
      option :opt_array, variant: :array
      option :opt_single_choice, type: :choice do
        items [:a, :b, :c]
        default :a
      end
    end
  end
  op = jaba do
    # due to :allow_dupes these will be separate elems
    a 1, opt_single: 2, opt_array: [3, 4], opt_single_choice: :b
    a 1, opt_single: 5, opt_array: [6, 7], opt_single_choice: :c
    # dupes will be stripped
    b 8, opt_single: 9, opt_array: [10, 11], opt_single_choice: :b
    b 8, opt_single: 12, opt_array: [13, 14] # D08E9A99 opt_array will add to existing opt_array
    b 8 # ED3FB7CD will have no effect, duplicate warning issued
  end
  a = op[:root].get_attr(:a)
  a.value.must_equal [1, 1]
  a[0].option_value(:opt_single).must_equal 2
  a[0].option_value(:opt_single_choice).must_equal :b
  a[0].option_value(:opt_array).must_equal [3, 4]
  a[1].option_value(:opt_single).must_equal 5
  a[1].option_value(:opt_single_choice).must_equal :c
  a[1].option_value(:opt_array).must_equal [6, 7]

  b = op[:root].get_attr(:b)
  b.value.must_equal [8]
  b[0].option_value(:opt_single).must_equal 12
  b[0].option_value(:opt_single_choice).must_equal :b
  b[0].option_value(:opt_array).must_equal [10, 11, 13, 14]
  op[:warnings].must_equal ["Warning at #{src_loc("ED3FB7CD")}: [8] dupes stripped from 'b' attribute. See previous at #{src_loc("D08E9A99")}."]
end
