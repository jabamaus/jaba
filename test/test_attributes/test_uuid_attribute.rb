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
  a_uuid = "{1F824C00-702A-52EA-906E-54C0F6C87AED}"
  b_uuid = "{E4B88B6B-5EA8-5DE8-A73D-D65CEB533AEA}"
  c_uuid = "{44B023A5-12E8-5495-AAF0-9B6AF83C0338}"
  d_uuid = "{C1ACE80B-6A8A-501F-924C-652DE5E19B50}"

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
