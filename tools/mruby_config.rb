
mruby_config do |c|
  c.dest_dir = "#{__dir__}/../libs/mruby"
  c.gems = 
  [
    'mruby-array-ext',
    'mruby-bigint', # required by psuedo_uuid_from_string
    #'mruby-bin-mirb',
    #'mruby-bin-mrbc',
    #'mruby-bin-mruby',
    #'mruby-bin-strip',
    #'mruby-binding',
    #'mruby-catch',
    #'mruby-class-ext',
    #'mruby-cmath',
    #'mruby-compar-ext',
    'mruby-compiler',
    #'mruby-complex',
    #'mruby-data',
    #'mruby-dir',
    #'mruby-enum-chain',
    #'mruby-enum-ext',
    #'mruby-enum-lazy',
    #'mruby-enumerator',
    #'mruby-errno',
    #'mruby-error',
    #'mruby-eval',
    'mruby-exit',
    #'mruby-fiber',
    #'mruby-hash-ext',
    #'mruby-io',
    #'mruby-kernel-ext',
    #'mruby-math',
    #'mruby-metaprog',
    #'mruby-method',
    #'mruby-numeric-ext',
    #'mruby-object-ext',
    #'mruby-objectspace',
    #'mruby-os-memsize',
    #'mruby-pack',
    #'mruby-proc-binding',
    #'mruby-proc-ext',
    #'mruby-random', # shuffle
    #'mruby-range-ext',
    #'mruby-rational',
    #'mruby-set',
    #'mruby-sleep',
    #'mruby-socket',
    #'mruby-sprintf',
    #'mruby-string-ext',
    #'mruby-struct',
    #'mruby-symbol-ext',
    #'mruby-time',
    #'mruby-toplevel-ext',
  ]

  c.defines =
  [
    'MRB_UTF8_STRING',
    #"MRB_STR_LENGTH_MAX=0",
    #"MRB_ARY_LENGTH_MAX=0",
  ]

  c.presyms = %w(
    attr
    AttributeDef
    example
    FlagOptionDef
    global_method
    JDL
    JDLDef
    method
    MethodDef
    node
    note
    on_called
    title
    transient
    type
    variant
  )
end