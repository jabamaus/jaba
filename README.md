# jaba

To do:

- Should to_absolute base off JABA.cwd or dest_root? I think the latter...
- Remove src_root from globals and put into jaba.cache file
- consider having a globals per-type (eg cpp globals)
- validate when --src-root can be specified. Should be required if no .jaba files in cwd and disallowed if there are.
- rename $(root) to $(spec_root)?
- Check attribute validators when parsing cmd line.
- Should jaba target one 'language' (type) per run? Eg C++, C#
- Better logging of exception errors. Never return a backtrace to cmd line - ugly.
- Nasty that :export flag option always needs :no_delete
- Use did_you_mean? Eg
  Error at basic_dll.jaba:8: 'define' attribute not defined. Did you mean 'defines'?
- Combine jaba.input.json and jaba.output.json into just the latter?
- Have a 'jaba clean' command
- put simple type verification system into Property
- consider putting config attrs inside a block. It is a bit nasty doing multiple passes and ignoring attrs.
- there could be a directive on include statements that runs inlcuded file in new jaba instance
- validate platforms and architecture specs
- cpp attrs need to be split into project and config in reference manual
- tag attrs as control flow attrs somehow for benefit of docs
- add slnproperty which can address sln sections. Particularly useful when used with ExtensibilityGlobals
- disband VSProj in favour of VSUtilities module
- Make it so that all attributes have to have a type?
- way of validating key in hash attribute
- test build actions
- Move title/note/example into module and include
- more error reporting testing with actual files rather than blocks
- test opening sub types
- Have a command line switch to make all error messages contain absolute paths
- Sort jaba input/output files
- Add 'describe' method to everything which can be used as standard in error and log messages
- How customise jaba output file? Subclass vcxproj or jdl definition, or something else?
- support for 'overriding' attribute defs when opening types
- make_generator should be able to make subclasses of eg CppGenerator
- make paths in jaba.output.json relative to itself. Introduce json node writing api to wrap this up and to make it robust.
- think more about path handling in general and make it very consistent. eg all paths get to generators as absolute.
- Have a way of globally setting default for :platforms, :hosts and :configs (and for clearing)
- make file/dir attrs cleanpath
- sortable arrays must be of same type
- Make :nocheckexists do something
- check that only arrays and hashes can be exported
- test different default values and different validation for different platforms
- Think more about project 'skus'. Also, platforms support specific hosts. Where is that info stored?
- test :required flag compatibility
- Revisit set_to_default and wipe. Have way of clearing to default and clearing fully, but don't count that as set=true
- In defaults block are paths relative to the defaults file or the file of the definition being instanced?
- Consider something like  base: :__dir__ option on :dir attribute types to force a path to be relative to source definition file and not root
- Test __dir__
- Allow 'axes' of configs. Bear in mind that platforms can be any string.
- Have some kind of spec for flag_options, eg

flag_option :export do
  note 'do exporting'
  compatibility do
    'only works on array and hash' if !array? && !hash?
    end
  end
end

- Having two arrays that reference the same type causes problems with :expose. Need to resolve this.
Need to make it so that don't expose if attribute is not single value. Also need to prevent exposing
if there are multiple attrs, with a warning.

  attr_array :valid_archs, type: :reference do
    note 'List of architectures supported by this platform'
    referenced_type :arch
    flags :required, :no_sort
  end

  attr_array :default_archs, type: :reference do
    note 'List of default target architectures for this platform'
    referenced_type :arch
    flags :required, :no_sort
  end

  - check for duplicate filenames at generator level, with proper error reporting
  - Make contents of attr def defaults overidable by user, including calling super

  - Make _ID be id of the definition the code is in, such that it works even inside
      a block that is being executed in the context of a different jaba object

- Stop profiling test as a whole. Add a stresstest feature.
- Ability to reverse engineer jaba definitions from existing vsprojects would be awesome
- Should 'absolute' paths starting with / force 'root' to be disregarded and make paths relative to definition file or
  should use eg "#{__dir__}/main.cpp"?
- Add check for re-entrancy when evaluating default blocks
- consistent method names across tests and consistent brackets on must_equal
- Create a table of attr mappings from jaba->premake->cmake
- Bring back boolean reader, eg if debug?
- Add 'underlying type' to attribute types? eg file.dir/src_spec are strings. Use this for extra
  validation and also to sort using casecmp
- resolve issues around sorting with mixed type elements
- Add an init callback to definitions?
- Add wildcard validation to dir property
- jdl_exclude system

- Think about a 'configure' system. Eg could have a configure block eg for ruby jaba file it might be

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

https://rix0r.nl/blog/2015/08/13/cmake-guide/
