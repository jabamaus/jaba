# jaba

To do:

- make paths in jaba.output.json relative to itself
- test absolute root paths
- Have a way of globally setting default for :platforms, :hosts and :configs (and for clearing)
- make file/dir attrs cleanpath
- introduce TopLevelDefinition?
- test subtypes, eg opening
- add id as a read only attr to all types
- sortable arrays must be of same type
- Do something with help strings
- check that only arrays and hashes can be exported
- test different default values and different validation for different platforms
- jaba.input.json should include flags
- Think more about project 'skus'. Also, platforms support specific hosts. Where is that info stored?
- test :required flag compatibility
- Revisit set_to_default and wipe. Have way of clearing to default and clearing fully, but don't count that as set=true
- In defaults block are paths relative to the defaults file or the file of the definition being instanced?
- Improve how jaba tests are invoked
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