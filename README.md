# jaba

To do:

- make paths in jaba.output.json relative to itself. Introduce json node writing api to wrap this up and to make it robust.
- think more about path handling in general and make it very consistent. eg all paths get to generators as absolute.
- test absolute root paths
- Have a way of globally setting default for :platforms, :hosts and :configs (and for clearing)
- make file/dir attrs cleanpath
- test subtypes, eg opening
- sortable arrays must be of same type
- Do something with help strings
- check that only arrays and hashes can be exported
- test different default values and different validation for different platforms
- Think more about project 'skus'. Also, platforms support specific hosts. Where is that info stored?
- test :required flag compatibility
- Revisit set_to_default and wipe. Have way of clearing to default and clearing fully, but don't count that as set=true
- In defaults block are paths relative to the defaults file or the file of the definition being instanced?
- Consider something like  base: :__dir__ option on :dir attribute types to force a path to be relative to source definition file and not root
- Test __dir__
- Allow 'axes' of configs
- Have some kind of spec for flag_options, eg

flag_option :export do
  help 'do exporting'
  compatibility do
    'only works on array and hash' if !array? && !hash?
    end
  end
end

- Rename attr_flags to attr_def_flags
- Having two arrays that reference the same type causes problems with :expose. Need to resolve this.
Need to make it so that don't expose if attribute is not single value. Also need to prevent exposing
if there are multiple attrs, with a warning.

  attr_array :valid_archs, type: :reference do
    help 'List of architectures supported by this platform'
    referenced_type :arch
    flags :required, :nosort
  end

  attr_array :default_archs, type: :reference do
    help 'List of default target architectures for this platform'
    referenced_type :arch
    flags :required, :nosort
  end

  - check for duplicate filenames at generator level, with proper error reporting
  - Make contents of attr def defaults overidable by user, including calling super

  - Sort out _ID
    - Make _ID be id of the definition the code is in, such that it works even inside
      a block that is being executed in the context of a different jaba object
    - rename existing _ID to id

- give attributes a 'title' and a 'help' string. title can be used when dumping help, help string can be used in error msgs
- Stop profiling test as a whole. Add a stresstest feature.
- Ability to reverse engineer jaba definitions from existing vsprojects would be awesome
- Should 'absolute' paths starting with / force 'root' to be disregarded and make paths relative to definition file or
  should use eg "#{__dir__}/main.cpp"?
- Support for opening instances as well as types
- Add check for re-entrancy when evaluating default blocks
- consistent method names across tests and consistent brackets on must_equal
- Test cpp json output
- Create a table of attr mappings from jaba->premake->cmake
- Think about a 'configure' system. Eg could have a configure block eg for ruby jaba file it might be
- Bring back boolean reader, eg if debug?
- Consider whether arrays should be allowed to be set with single value. I'm thinking not again.
- Add 'underlying type' to attribute types? eg file.dir/src_spec are strings. Use this for extra
  validation and also to sort using casecmp
- resolve issues around sorting with mixed type elements
- Make it so that only top level jaba type can make its own sub types
- Add an init callback to definitions?
- Make sure only one globals can be created
- Add wildcard validation to dir property
- Only load relevant definition files when executing unit tests, to speed them up.

cpp :a do
  _init do
     make_file('a')
  end
end

configure do
  attr :extensions, type: :multichoice do
    items Dir.glob(ext_dir) # get list of ruby extension
  end
  attr :static, type: :bool do
    default false
  end
  ...
end

When jaba is run and no configure file has been generated, jaba generates one from the above definition which is just a flat list.
Maybe a yml file?

jaba.configure:

static = false
extension_json = true
extension_ripper = true
...

This is then used in the jaba build definition eg

cpp :ruby do
  type (static ? :lib : :dll)

  case extension
  when :json
  ...
  end
end




* Jaba does not try to be a complete cross platform 'API' to underlying build systems. It recognises where there is obvious commonality,
eg include paths, defines, libs, etc, but where things diverge across systems you can simply drop down and address that system directly,
because defining conditional data is very easy.
* Jaba aims to be lightweight. An executable and a bundle of ruby source files. Without sacrificing power and fleixibilty.
* Jaba aims to excel at validation and error reporting.

FAQ
Q: Why is Jaba so aggressive with sorting and stripping duplicates?
A: Because Jaba cares a lot about a clean build, and about deterministic minimum noise generation.

Q: Why is Jaba library code style not very 'ruby'?
A: The code is written in a style that is the easiest to step through in an IDE debugger, which is an essential tool in the development process