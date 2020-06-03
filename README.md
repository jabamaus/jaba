# jaba

To do:

- make paths in jaba.output.json relative to itself. Introduce json node writing api to wrap this up and to make it robust.
- think more about path handling in general and make it very consistent. eg all paths get to generators as absolute.
- test absolute root paths
- Have a way of globally setting default for :platforms, :hosts and :configs (and for clearing)
- make file/dir attrs cleanpath
- test subtypes, eg opening
- add id as a read only attr to all types
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
  - could change last_call_location to an array to track all call locations
  - Make _ID be id of the definition the code is in, such that it works even inside
    a block that is being executed in the context of a different jaba object
  - give attributes a 'title' and a 'help' string. title can be used when dumping help, help string can be used in error msgs
- Stop profiling test as a whole. Add a stresstest feature.
- Ability to reverse engineer jaba definitions from existing vsprojects would be awesome
- Should 'absolute' paths starting with / force 'root' to be disregarded and make paths relative to definition file or
  should use eg "#{__dir__}/main.cpp"?
- Support for opening instances as well as types
- Add check for re-entrancy when evaluating default blocks
- consistent method names across tests and consistent brackets on must_equal
- Should string attrs be initialised to ''?
- Test cpp json output
