module JABA
  class AttributeArray < AttributeBase
    def initialize(attr_def, node)
      super(attr_def, node)
      @elems = []
      @excludes = []
      if attr_def.default_set? && !attr_def.default_is_block?
        set(attr_def.get_default, __call_on_set: false)
      end
    end

    def to_s = "#{attr_def} [#{@elems.size} elems]"
    def describe = "'#{node.id}.#{attr_def.name}' array attribute"

    def value
      record_last_call_location
      if !set?
        if attr_def.default_is_block?
          values = JABA.context.execute_attr_default_block(self)
          at = attr_def.attr_type
          return values.map { |e| at.map_value(e) }
        elsif JABA.context.in_attr_default_block?
          attr_error("Cannot read uninitialised #{describe} - it might need a default value")
        end
      end
      values = @elems.map { |e| e.value }
      values.freeze # make read only
    end

    # Options:
    #  - delete: Immediately delete specified elems from array
    #  - exclude: Cache exclusion and apply later. Allows order independent deletion and deletion
    #             of elements added later by dependencies
    #
    def set(*args, prefix: nil, postfix: nil, delete: nil, exclude: nil, **kwargs, &block)
      record_last_call_location

      # It is possible for values to be nil, which happens if no args are passed. This can happen if the user
      # wants to remove something from the array
      #
      values = if block_given?
          value_from_block(&block)
        else
          #if @attr_def.compound?
          #  attr_error("Compound attributes require a block")
          #end
          args.shift
        end

      values = Array(values)

      # If attribute has not been set and there is a default that was specified in block form 'pull' the values in
      # and prepend them to the values passed in. Defaults specified in blocks are handled lazily to allow the default
      # value to make use of other attributes.
      #
      if !set? && attr_def.default_is_block?
        default_values = JABA.context.execute_attr_default_block(self)
        if !default_values.array?
          JABA.error("#{describe} 'default' invalid: requires an array not a '#{default_values.class}'", errobj: attr_def.get_default)
        end
        default_values.each do |d|
          attr_def.attr_type.validate_value(attr_def, d) do |msg|
            JABA.error("#{describe} 'default' invalid: #{msg}", errobj: attr_def)
          end
        end
        values.prepend(*default_values)
      end

      values.each do |val|
        val = apply_pre_post_fix(prefix, postfix, val)

        elem = make_elem(val, *args, add: false, **kwargs)
        existing = nil
        if !attr_def.has_flag?(:allow_dupes) # && !@attr_def.compound?
          existing = @elems.find { |e| e.raw_value == elem.raw_value }
        end

        if existing
          JABA.warn("Stripping duplicate '#{val.inspect_unquoted}' from #{describe}. See previous at #{existing.src_loc.describe}. " \
          "Flag with :allow_dupes to allow.")
        else
          @elems << elem
        end
      end

      if delete
        process_removes(Array(delete).map { |r| apply_pre_post_fix(prefix, postfix, r) }, mode: :delete)
      end
      if exclude
        @excludes.concat(Array(exclude).map { |r| apply_pre_post_fix(prefix, postfix, r) })
      end

      @set = true
      nil
    end

    def make_elem(val, *args, add: true, **kwargs)
      e = AttributeElement.new(@attr_def, @node)
      e.set(val, *args, **kwargs)
      if add
        @elems << e
      end
      e
    end

    # If the attribute was never set by the user and it has a default specified in block form ensure that the default value
    # is applied. Call set with no args to achieve this.
    #
    def finalise
      if !set? && attr_def.default_is_block?
        set
      end
    end

    # Clone other attribute and append to this array. Other attribute has already been validated and had any reference resolved.
    # just clone raw value and options. Flags will be processed after, eg stripping duplicates.
    #
    def insert_clone(other)
      value_options = other.value_options
      f_options = other.flag_options
      val = Marshal.load(Marshal.dump(other.raw_value))
      make_elem(val, *f_options, validate: false, **value_options)
    end

    def apply_pre_post_fix(pre, post, val)
      if pre || post
        if !val.string?
          attr_error("When setting #{describe} prefix/postfix option can only be used with string arrays")
        end
        "#{pre}#{val}#{post}"
      else
        val
      end
    end

    def at(index) = @elems[index]

    def visit_attr(&block)
      @elems.delete_if do |attr|
        attr.visit_attr(&block) == :delete ? true : false
      end
    end

    def process_removes(to_remove, mode:)
      if !to_remove.empty?
        n_elems = @elems.size
        @elems.delete_if do |e|
          to_remove.any? do |d|
            val = e.value
            if d.proc?
              d.call(val)
            elsif d.is_a?(Regexp)
              if !val.string? && !val.symbol?
                attr_error("#{mode} with a regex can only operate on strings or symbols")
              end
              val.match(d)
            else
              d == val
            end
          end
        end
        if @elems.size == n_elems
          JABA.warn("'#{to_remove}' did not #{mode} any elements")
        end
      end
    end

    def process_flags
      process_removes(@excludes, mode: :exclude)
      if !attr_def.has_flag?(:no_sort)
        begin
          @elems.stable_sort!
        rescue StandardError
          attr_error("Failed to sort #{describe}. Might be missing <=> operator")
        end
      end
    end
  end
end
