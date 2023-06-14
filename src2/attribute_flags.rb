module JABA
  class AttributeFlag
    API = APIBuilder.define(:title, :note, :example, :compatible?, :init_attr_def)

    def initialize(name)
      @name = name
      @title = nil
      @notes = []
      @examples = []
      @on_compatible = nil
      @on_init_attr_def = nil
    end

    def name = @name
    def describe = "'#{name.inspect_unquoted}' attribute definition flag"

    def set_title(t) = @title = t
    def title = @title
    def set_note(n) = @notes << n
    def notes = @notes
    def set_example(e) = @examples << e
    def examples = @examples

    def set_compatible?(&block) = @on_compatible = block
    def on_compatible = @on_compatible
    def set_init_attr_def(&block) = @on_init_attr_def = block
    def on_init_attr_def = @on_init_attr_def
  end

  Context.define_attr_flag :allow_dupes do
    title "Array duplicates strategy"
    note "Allows array attributes to contain duplicates. If not specified duplicates are stripped"
    compatible? do |attr_def|
      if !attr_def.array?
        definition_error("only allowed on array attributes")
      end
    end
  end

  Context.define_attr_flag :attr_option do
    title "Flags the attribute as being an option for another attribute"
  end

  Context.define_attr_flag :exportable do
    title "Attribute is exportable"
    note "Flags an attribute as being able to be exported to dependents. Only array and hash attributes can be flagged with this."
    compatible? do |attr_def|
      if !attr_def.array? && !attr_def.hash?
        definition_error("only allowed on array/hash attributes")
      end
    end
    init_attr_def do |attr_def|
      attr_def.set_flag_options(:export, :export_only)
    end
  end

  Context.define_attr_flag :no_check_exist do
    title "Do not check that specified paths exist on disk"
    note "Applies to file, dir and src attribute types."
    compatible? do |attr_def|
      case attr_def.type_id
      when :file, :dir, :src
      else
        definition_error("only allowed on file, dir and src attribute types")
      end
    end
  end

  Context.define_attr_flag :no_sort do
    title "Do not sort array attributes"
    note "Allows array attributes to remain in the order they are set in. If not specified arrays are sorted"
    compatible? do |attr_def|
      if !attr_def.array?
        definition_error("only allowed on array attributes")
      end
    end
  end

  Context.define_attr_flag :node_option do
    title "Flags the attribute as being callable as an option passed into a definition"
    example %Q{
  target :my_app, root: "my_root" do # 'root' attr is flagged with :node_option
    ...
  end
    }
  end

  Context.define_attr_flag :overwrite_default do
    title "If set default is overwritten if set by user else default is extended"
    compatible? do |attr_def|
      if attr_def.single?
        definition_error("only allowed on array and hash attributes")
      end
    end
  end

  Context.define_attr_flag :per_target do
    title "Flags attributes inside the target namespace as being per-target rather than per-config"
  end

  Context.define_attr_flag :per_config do
    title "Flags attributes inside the target namespace as being per-config rather than per-target"
  end

  Context.define_attr_flag :read_only do
    title "Prevents user from writing to value"
    note "Specifies that the attribute can only be read and not set from user definitions. The value will be initialised inside Jaba"
  end

  Context.define_attr_flag :required do
    title "Force user to supply a value"
    note "Specifies that the definition writer must supply a value for this attribute"
    compatible? do |attr_def|
      if attr_def.default_set?
        definition_error("can only be specified if no default specified")
      end
    end
  end
end
