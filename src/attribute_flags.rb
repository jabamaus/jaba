module JABA
  class AttributeFlag
    def initialize(name) = @name = name
    def name = @name
    def describe = "'#{name.inspect_unquoted}' flag"
    def compatible?(attr_def); end # override as necessary
    def init_attr_def(attr_def); end # override as necessary
  end

  class AttributeFlagAllowDupes < AttributeFlag
    def initialize = super(:allow_dupes)

    def compatible?(attr_def)
      if !attr_def.array?
        yield "only allowed on array attributes"
      end
    end

    def init_attr_def(attr_def)
      attr_def.add_note "Duplicates are allowed"
    end
  end

  class AttributeFlagExportable < AttributeFlag
    def initialize = super(:exportable)

    def compatible?(attr_def)
      if !attr_def.array? && !attr_def.hash?
        yield "only allowed on array/hash attributes"
      end
      if attr_def.has_flag?(:node_option)
        yield "attributes flagged with :node_option cannot be :exportable"
      end
    end

    def init_attr_def(attr_def)
      attr_def.add_flag_option(:export) do
        title "Export specified elements to dependent targets"
        note "Set on source target and on dependent target"
      end
      attr_def.add_flag_option(:export_only) do
        title "Export specified elements to dependent targets"
        note "Only set on the dependent target"
      end
    end
  end

  class AttributeFlagNoCheckExist < AttributeFlag
    def initialize = super(:no_check_exist)

    def compatible?(attr_def)
      case attr_def.type_id
      when :file, :dir, :src
      else
        yield "only allowed on file, dir and src attribute types"
      end
    end

    def init_attr_def(attr_def)
      attr_def.add_note "Does not check if path exists at generation time"
    end
  end

  class AttributeFlagNoSort < AttributeFlag
    def initialize = super(:no_sort)

    def compatible?(attr_def)
      if !attr_def.array?
        yield "only allowed on array attributes"
      end
    end

    def init_attr_def(attr_def)
      attr_def.add_note "Unsorted"
    end
  end

  class AttributeFlagNodeOption < AttributeFlag
    def initialize = super(:node_option)

    # TODO
  end

  class AttributeFlagOverwriteDefault < AttributeFlag
    def initialize = super(:overwrite_default)

    def compatible?(attr_def)
      if attr_def.single?
        yield "only allowed on array and hash attributes"
      end
    end

    def init_attr_def(attr_def)
      attr_def.add_note "Default value is overwritten rather than extended"
    end
  end

  class AttributeFlagPerTarget < AttributeFlag
    def initialize = super(:per_target)

    def compatible?(attr_def)
      if attr_def.node_def.name != "target"
        yield "only allowed on target node attributes"
      end
    end

    def init_attr_def(attr_def)
      attr_def.add_note "Set on a per-target basis"
    end
  end

  class AttributeFlagReadOnly < AttributeFlag
    def initialize = super(:read_only)

    def init_attr_def(attr_def)
      attr_def.add_note "Read only"
    end
  end

  class AttributeFlagRequired < AttributeFlag
    def initialize = super(:required)

    def compatible?(attr_def)
      if attr_def.default_set?
        yield "only allowed if no default specified"
      end
    end

    def init_attr_def(attr_def)
      attr_def.add_note("Must be specified")
    end
  end
end
