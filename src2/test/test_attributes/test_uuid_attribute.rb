jtest "generates a UUID from a string" do
  jdl do
    attr "a", type: :uuid do
      default "a"
    end
    attr "b", type: :uuid do
      default do # block form
        "b"
      end
    end
    attr_array "c", type: :uuid do
      default ["a", "b"]
      flags :no_sort
    end
    attr_array "d", type: :uuid do
      default do # block form
        ["a", "b"]
      end
      flags :no_sort
    end
    attr_hash "e", key_type: :symbol, type: :uuid do
      default({ k1: "a", k2: "b" })
    end
    attr_hash "f", key_type: :symbol, type: :uuid do
      default do # block form
        { k1: "a", k2: "b" }
      end
    end
  end
  a_uuid = "{239B21D9-641E-517D-9532-88054E2B777F}"
  b_uuid = "{DD1FBB35-694F-574F-B508-0517B327CA75}"
  c_uuid = "{B2172CAC-43F9-510F-B1FD-19EAD77AEFB0}"
  d_uuid = "{87A70C95-FAA5-575A-BA88-EE3E4DBCFB58}"

  jaba do
    a.must_equal(a_uuid)
    a "b"
    a.must_equal(b_uuid)
    b.must_equal(b_uuid)

    c.must_equal [a_uuid, b_uuid]
    c ["c", "d"]
    c.must_equal [a_uuid, b_uuid, c_uuid, d_uuid]

    d.must_equal [a_uuid, b_uuid]
    d ["c", "d"]
    d.must_equal [a_uuid, b_uuid, c_uuid, d_uuid]

    e.must_equal({ k1: a_uuid, k2: b_uuid })
    e :k1, "c" # overwrite default
    e :k3, "d" # insert
    e.must_equal({ k1: c_uuid, k2: b_uuid, k3: d_uuid })

    f.must_equal({ k1: a_uuid, k2: b_uuid })
    f :k1, "c" # overwrite default
    f :k3, "d" # insert
    f.must_equal({ k1: c_uuid, k2: b_uuid, k3: d_uuid })
  end
end
