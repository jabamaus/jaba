module JABA
  module OS
    def self.windows? = true
    def self.mac? = false
  end

  # SymbolKeyHash hash converts keys to symbols so can lookup with strings or symbols
  class SymbolKeyHash < Hash
    def [](key) = super(key.to_sym)
    def has_key?(key) = super(key.to_sym)
    def []=(key, value); super(key.to_sym, value); end
  end

  module VSUtilities
    def xml_group(w, tag, label: nil, label_at_end: true, condition: nil, close: false, depth: 1)
      if !close
        w.write_raw "#{"  " * depth}<#{tag}"
        w.write_raw " Label=\"#{label}\"" if (label && !label_at_end)
        w.write_raw " Condition=\"#{condition}\"" if condition
        w.write_raw " Label=\"#{label}\"" if (label && label_at_end)
        w << ">"
      end

      if block_given?
        yield
        close = true
      end

      if close
        w << "#{"  " * depth}</#{tag}>"
      end
    end

    def item_group(w, **kwargs, &block) = xml_group(w, "ItemGroup", **kwargs, &block)
    def property_group(w, **kwargs, &block) = xml_group(w, "PropertyGroup", **kwargs, &block)
    def import_group(w, **kwargs, &block) = xml_group(w, "ImportGroup", **kwargs, &block)
    def item_definition_group(w, **kwargs, &block) = xml_group(w, "ItemDefinitionGroup", **kwargs, &block)

    def write_keyvalue_attr(w, kv_attr, depth: 2)
      kv_attr.each do |key, attr|
        condition = attr.option_value(:condition, fail_if_not_found: false)
        write_keyvalue(w, key, attr.value, condition: condition)
      end
    end

    def write_keyvalue(w, key, val, condition: nil, depth: 2)
      return if val.empty?
      w << if condition
        "#{"  " * depth}<#{key} Condition=\"#{condition}\">#{val}</#{key}>"
      else
        "#{"  " * depth}<#{key}>#{val}</#{key}>"
      end
    end

    def cfg_condition(cfg_name, platform)
      "'$(Configuration)|$(Platform)'=='#{cfg_name}|#{platform}'"
    end
  end
end
