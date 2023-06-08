jtest "requires items to be set" do
  jdl do
    attr "a", type: :choice # A2047AFC
  end
  assert_jaba_error "Error at #{src_loc("A2047AFC")}: 'a' attribute invalid - 'items' must be set." do
    jaba do end
  end
end

jtest "warns if items contains duplicates" do
  jdl do
    attr "b", type: :choice do
      items [:a, :a, :b, :b] # 234928DC
    end
  end
  op = jaba do end
  op[:warnings].size.must_equal 1
  op[:warnings][0].must_equal "Warning at #{src_loc("234928DC")}: 'items' contains duplicates."
end

jtest "requires default to be in items" do
  jdl do
    attr "a", type: :choice do
      items [1, 2, 3]
      default 4 # 8D88FA0D
    end
  end
  assert_jaba_error "Error at #{src_loc("8D88FA0D")}: 'a' attribute invalid - 'default' invalid - must be one of [1, 2, 3] but got '4'." do
    jaba do end
  end
  jdl do
    attr :a, variant: :array, type: :choice do
      items [1, 2, 3]
      default [1, 2, 4] # CDCFF3A7
    end
  end
  assert_jaba_error "Error at #{src_loc("CDCFF3A7")}: 'a' attribute invalid - 'default' invalid - must be one of [1, 2, 3] but got '4'." do
    jaba do end
  end
end

jtest "rejects invalid choices" do
  jdl do
    attr :a, type: :choice do
      items [:a, :b, :c]
    end
    attr :b, variant: :array, type: :choice do
      items [:a, :b, :c]
    end
  end
  jaba do
    JTest.assert_jaba_error "Error at #{JTest.src_loc("21E33D49")}: 'a' attribute invalid - must be one of [:a, :b, :c] but got ':d'." do
      a :d # 21E33D49
    end
    JTest.assert_jaba_error "Error at #{JTest.src_loc("E22800D3")}: 'b' attribute invalid - must be one of [:a, :b, :c] but got ':d'." do
      b [:a, :b, :c, :d] # E22800D3
    end
  end
end

jtest "can be set from cmdline" do
  jdl do
    attr "a", type: :choice do
      items [:a, :b, :c]
      default :a
    end
    attr "b", type: :choice do
      items [:a, :b, :c, nil]
      default :a
    end
    attr "c", type: :choice do
      items [1, :a, "b"]
      default "b"
    end
  end
  jaba(global_attrs_from_cmdline: { 'a': "b", 'b': "", 'c': "1" }) do
    a.must_equal :b
    b.must_be_nil
    c.must_equal 1
  end

  op = jaba(global_attrs_from_cmdline: { 'a': "d" }, want_exceptions: false) do end
  op[:error].must_equal "Error: 'd' invalid value for 'a' attribute - [a|b|c] expected."
end
