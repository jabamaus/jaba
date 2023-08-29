# frozen_string_literal: false

jtest "supports vs_quote!" do
  "p".vs_quote!.must_equal("p") # no space or macro, no quote
  '"p"'.vs_quote!.must_equal('"p"') # no space or macro, no quote
  '"p'.vs_quote!.must_equal('"p') # no space or macro, no quote
  'p"'.vs_quote!.must_equal('p"') # no space or macro, no quote
  " p".vs_quote!.must_equal('" p"') # space, quote
  "$(Var)".vs_quote!.must_equal('"$(Var)"')   # macro, quote
end

jtest "supports contains_slashes" do
  "a".contains_slashes?.must_equal false
  "a/b".contains_slashes?.must_equal true
  'a\\b'.contains_slashes?.must_equal true
  "/".contains_slashes?.must_equal true
  '\\'.contains_slashes?.must_equal true
end
