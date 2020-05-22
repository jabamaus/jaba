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