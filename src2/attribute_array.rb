module JABA
  ArraySentinel = [].freeze

  class AttributeArray < AttributeBase
    def initialize(attr_def, node)
      super(attr_def, node)
      @elems = []
      @excludes = []
    end

    def to_s = "#{attr_def} [#{@elems.size} elems]" # For debugger

    def value
      values = if set?
          @elems.map { |e| e.value }
        elsif attr_def.default_set?
          values = JABA.context.execute_attr_def_block(self, attr_def.default)
          validate_default_block_value(values)
          at = attr_def.attr_type
          values.map { |e| at.map_value(e, self) }
        elsif JABA.context.in_attr_def_block?
          outer = JABA.context.outer_attr_def_block_attr
          outer.attr_error("#{outer.describe} default read uninitialised #{describe} - it might need a default value")
        else
          ArraySentinel
        end
      values.freeze # make read only
    end

    # Options:
    #  - delete: Immediately delete specified elems from array
    #  - exclude: Cache exclusion and apply later. Allows order independent deletion and deletion
    #             of elements added later by dependencies
    def set(*args,
            prefix: nil,
            postfix: nil,
            delete: nil,
            exclude: nil,
            __force_set_default: false,
            **kwargs, &block)

      # It is possible for values to be nil, which happens if no args are passed. This can happen if the user
      # wants to remove something from the array
      #
      values = if block_given?
          value_from_block(&block)
        else
          args.shift
        end

      at = attr_def.attr_type

      values = Array(values).flat_map do |val|
        val = apply_pre_post_fix(prefix, postfix, val)
        at.map_value_array(val, self)
      end

      # If attribute has not been set and there is a default 'pull' the values in
      # and prepend them to the values passed in. Allows default value to make use of other attributes.
      if !set? && attr_def.default_set? && (!attr_def.has_flag?(:overwrite_default) || __force_set_default)
        default_values = JABA.context.execute_attr_def_block(self, attr_def.default)
        validate_default_block_value(default_values)
        values.prepend(*default_values)
      end

      dupes = first_dupe = nil
      
      values.each do |val|
        # need to make an element so that it has correct mapped value for duplicates
        # comparison. It will be discarded if it is a duplicate and :allow_dupes not set.
        elem = make_elem(val, *args, add: false, **kwargs)
        if attr_def.has_flag?(:allow_dupes)
          @elems << elem
        else
          existing = @elems.find { |e| e.raw_value == elem.raw_value }
          if existing
            if elem.flag_options.empty? && elem.value_options.empty?
              first_dupe ||= existing
              dupes ||= []
              dupes << val
            else
              existing.set_last_call_location(last_call_location)
              existing.set(val, *args, **kwargs)
            end
          else
            @elems << elem
          end
        end
      end

      if dupes
        msg = "Stripping duplicates #{dupes} from #{describe}"
        if first_dupe.src_loc != src_loc
          msg << ". See previous at #{first_dupe.src_loc.src_loc_describe}"
        end
        JABA.warn(msg, line: src_loc)
      end

      if delete
        process_removes(make_removes(delete, at, prefix, postfix, *args, **kwargs), mode: :delete)
      end
      if exclude
        @excludes.concat(make_removes(exclude, at, prefix, postfix, *args, **kwargs))
      end
      process_removes(@excludes, mode: :exclude)

      @set = true
      nil
    end

    def validate_default_block_value(value)
      if !value.is_a?(Array)
        attr_error("#{describe} 'default' invalid - expects an array but got '#{value.inspect_unquoted}'", errobj: attr_def.default)
      end
      at = attr_def.attr_type
      value.each do |d|
        at.validate_value(attr_def, d) do |msg|
          attr_error("#{describe} 'default' invalid - #{msg}", errobj: attr_def)
        end
      end
    end

    def make_elem(val, *args, add: true, **kwargs)
      e = AttributeElement.new(@attr_def, @node)
      e.set_last_call_location(last_call_location)
      e.set(val, *args, **kwargs)
      if add
        @elems << e
      end
      e
    end

    # If the attribute was never set by the user and it has a default set ensure that the default value
    # is applied. Call set with no args to achieve this.
    #
    def finalise
      if !set? && attr_def.default_set?
        set(__force_set_default: true)
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
          attr_error("[prefix|postfix] can only be applied to string values")
        end
        "#{pre}#{val}#{post}"
      else
        val
      end
    end

    def clear = @elems.clear
    def empty? = @elems.empty?
    def [](index) = @elems[index]
    def each(&block) = @elems.each(&block)
    
    def map_value!(&block)
      @elems.each do |e|
        e.map_value!(&block)
      end
    end

    def make_removes(values, at, prefix, postfix, *args, **kwargs)
      Array(values).flat_map do |val|
        if val.proc? || val.is_a?(Regexp)
          val
        else
          val = apply_pre_post_fix(prefix, postfix, val)
          Array(at.map_value_array(val, self)).map { |e| make_elem(e, *args, add: false, **kwargs) }
        end
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
              val =~ d ? true : false
            else
              d.value == val
            end
          end
        end
        if @elems.size == n_elems
          JABA.warn("no elements deleted", line: src_loc)
        end
      end
    end

    def process_flags
      process_removes(@excludes, mode: :exclude)
      if !attr_def.has_flag?(:no_sort)
        sort!
      end
    end

    def sort!
      begin
        @elems.stable_sort!
      rescue StandardError => e
        attr_error("Failed to sort #{describe}: #{e}")
      end
    end
  end
end
