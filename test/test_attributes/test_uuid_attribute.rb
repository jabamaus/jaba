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
    attr "c", variant: :array, type: :uuid do
      default ["a", "b"]
      flags :no_sort
    end
    attr "d", variant: :array, type: :uuid do
      default do # block form
        ["a", "b"]
      end
      flags :no_sort
    end
    attr "e", variant: :hash, type: :uuid do
      key_type :string
      default({ k1: "a", k2: "b" })
    end
    attr "f", variant: :hash, type: :uuid do
      key_type :string
      default do # block form
        { k1: "a", k2: "b" }
      end
    end
  end
  a_uuid = "{06C50E6D-8FEA-55AC-3639-0000BD23CA42}"
  b_uuid = "{06C50E6D-8FEA-55AC-4E45-0000B16D3B61}"
  c_uuid = "{06C50E6D-8FEA-55AC-6651-0000A5B6AC80}"
  d_uuid = "{06C50E6D-8FEA-55AC-7E5D-00009A001D9F}"

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
