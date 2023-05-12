class Class
  # Allow setting and getting a block as a member variable.
  #
  def attr_block(attr)
    class_eval("def #{attr}(&block) ; block_given? ? @#{attr} << block : @#{attr} ; end", __FILE__, __LINE__)
  end

  # Member variable must be initialised.
  #
  def attr_bool(attr)
    class_eval("def #{attr}? ; @#{attr} ; end", __FILE__, __LINE__)
    class_eval("def #{attr}=(val) ; @#{attr} = val ; end", __FILE__, __LINE__)
  end
end

class Object
  def boolean? = (is_a?(TrueClass) || is_a?(FalseClass))
  def integer? = is_a?(Integer)
  def string? = is_a?(String)
  def symbol? = is_a?(Symbol)
  def proc? = is_a?(Proc)
end

# In jaba string and symbols are interchangeable in case statements
class String
  alias_method :old_case_equality, :===
  def ===(other)
    if other.is_a?(Symbol)
      self == other.to_s
    else
      old_case_equality(other)
    end
  end
end

# In jaba string and symbols are interchangeable in case statements
class Symbol
  alias_method :old_case_equality, :===
  def ===(other)
    if other.is_a?(String)
      self == other.to_sym
    else
      old_case_equality(other)
    end
  end
end

class String
  def validate_path
    JABA.error("block expected") if !block_given?
    if include?('\\')
      yield "'#{self}' contains backslashes"
    end
  end

  # Returns true if string contains '*' wildcard character.
  #
  def wildcard? = self =~ /\*/ ? true : false

  def contains_slashes? = self =~ /(\\)|(\/)/ ? true : false

  # Quote if string contains a space or a macro.
  #
  def vs_quote!
    quote! if self =~ / |\$\(/
    self
  end

  def to_escaped_xml
    gsub(/["'&<>\n]/) do |match|
      case match
      when '"'
        "&quot;"
      when "'"
        "&apos;"
      when "&"
        "&amp;"
      when "<"
        "&lt;"
      when ">"
        "&gt;"
      when "\n"
        "&#x0D;&#x0A;"
      end
    end
  end

  def to_escaped_DOS
    gsub(/[\^|<>&]/) do |match|
      case match
      when "^", "|", "<", ">", "&"
        "^#{match}"
      end
    end
  end
end

class Array
  def jaba_sort_topological!(...)
    sort_topological!(...)
  rescue TSort::Cyclic => e
    JABA.error(e.message, errobj: e.instance_variable_get(:@errobj))
  end

  # Joins array for use in msbuild files optionally adding an 'inherit' string. Returns nil if string is empty, unless forced.
  #
  def vs_join(separator: ";", inherit: nil, force: false)
    str = if empty?
        force ? inherit : nil
      else
        j = join(separator)
        if inherit
          j << separator << inherit
        end
        j
      end
    if !str || (str.empty? && !force)
      return nil
    else
      str
    end
  end

  # Joins array elements (paths) into a separted string with all the necessary quoting applied and
  # convert to backslashes. Returns nil if array is empty, unless forced.
  #
  def vs_join_paths(...)
    map(&:vs_quote!).vs_join(...)&.to_backslashes!
  end
end
