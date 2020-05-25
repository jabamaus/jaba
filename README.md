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
- look at requiring bool attrs to be set. Currently not possible as default set to false