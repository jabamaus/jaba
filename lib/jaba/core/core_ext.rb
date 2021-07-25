# frozen_string_literal: true

##
#
module JABACoreExt

  ##
  #
  refine Class do
    
    ##
    # Allow setting and getting a block as a member variable.
    #
    def attr_block(attr)
      class_eval("def #{attr}(&block) ; block_given? ? @#{attr} << block : @#{attr} ; end", __FILE__, __LINE__)
    end
    
    ##
    # Member variable must be initialised.
    #
    def attr_bool(attr)
      class_eval("def #{attr}? ; @#{attr} ; end", __FILE__, __LINE__)
      class_eval("def #{attr}=(val) ; @#{attr} = val ; end", __FILE__, __LINE__)
    end
  
    ##
    #
    def name_no_namespace
      to_s.split('::').last
    end
    
  end

  ##
  #
  refine Object do

    ##
    #
    def boolean?
      (is_a?(TrueClass) || is_a?(FalseClass))
    end
    
    ##
    #
    def integer?
      is_a?(Integer)
    end
    
    ##
    #
    def string?
      is_a?(String)
    end
    
    ##
    #
    def symbol?
      is_a?(Symbol)
    end

    ##
    #
    def proc?
      is_a?(Proc)
    end

    ##
    #
    def array?
      is_a?(Array)
    end

    ##
    #
    def hash?
      is_a?(Hash)
    end
    
    ##
    #
    def inspect_unquoted
      str = inspect
      str.delete_prefix!('"')
      str.delete_suffix!('"')
      str
    end
    
  end

  ##
  #
  refine String do

    ##
    #
    def validate_path
      JABA.error('block expected') if !block_given?
      if include?('\\')
        yield 'contains backslashes'
      end
    end

    ##
    # Cleans path by removing all extraneous ., .. and slashes. Supports windows and UNIX style absolute paths
    # and UNC paths.
    #
    def cleanpath
      path = split_path.join('/')

      # Preserve leading slash(es) if its a UNC path or UNIX style absolute path
      #
      if start_with?('//')
        path.insert(0, '//')
      elsif start_with?('/')
        path.insert(0, '/')
      elsif path.empty?
        path.concat('.')
      elsif path[1] == ':'
        path[0] = path[0].chr.upcase # Capitalise drive letter
      end

      path
    end

    ##
    # 'nil_if_dot: true' returns nil in the case that the path ends up as '.'
    # 'no_dot_dot: true' causes resulting relative path not to be filled with '..'. Used when generated vcxproj.filters files.
    #
    def relative_path_from(base, backslashes: false, nil_if_dot: false, no_dot_dot: false, trailing: false)
      return self if base.nil?
      parts = split_path(preserve_absolute_unix: true)
      base_parts = base.split_path(preserve_absolute_unix: true)
      while (!parts.empty? && !base_parts.empty? && parts[0] == base_parts[0])
        parts.shift
        base_parts.shift
      end
      if (!parts.empty? && parts[0].absolute_path?) || (!base_parts.empty? && base_parts[0].absolute_path?)
        JABA.error("Cannot turn '#{self}' into a relative path from '#{base}' - paths are unrelated")
      end
      result = []
      if !no_dot_dot
        result.concat(base_parts.fill('..'))
      end
      result.concat(parts)
      if result.empty?
        return nil if nil_if_dot
        result.push('.')
      end
      result = backslashes ? result.join('\\') : result.join('/')
      if trailing
        result << (backslashes ? '\\' : '/')
      end
      result
    end

    ##
    # Helper method that splits string on forward or backslashes, deleting any resulting blanks and uneeded '.'.
    # Does not preserve absolute UNIX paths or UNC paths, which the calling method is expected to handle.
    #
    def split_path(preserve_absolute_unix: false)
      result = []
      parts = split(/[\/\\]/)
      parts.delete('.')
      parts.delete('')
      i = 0
      s = parts.size
      while i < s
        p = parts[i]
        i += 1
        if p == '..'
          case result.last
          when '..', nil
            result.push('..')
          else
            result.pop
          end
        else
          result.push(p)
        end
      end
      if preserve_absolute_unix && absolute_unix_path?
        result.prepend('/')
      end
      result
    end

    ##
    #
    def absolute_unix_path?
      return false if empty?
      self[0].chr == '/' && ((size > 1 && self[1].chr != '/') || size == 1)
    end

    ##
    # Returns true if string is a windows or unix style absolute path.
    #
    def absolute_path?
      return false if empty?
      self[0].chr == '/' || self[0].chr == '\\' || (size > 1 && self[1].chr == ':')
    end

    ##
    # Returns true if string contains '*' wildcard character.
    #
    def wildcard?
      self =~ /\*/ ? true : false
    end

    ##
    #
    def basename
      File.basename(self)
    end

    ##
    #
    def extname
      File.extname(self)
    end

    ##
    #
    def dirname
      File.dirname(self)
    end

    ##
    #
    def to_absolute(clean: false)
      if absolute_path?
        clean ? cleanpath : self
      else
        abs = "#{JABA.invoking_dir}/#{self}"
        clean ? abs.cleanpath : abs
      end
    end

    ##
    #
    def to_backslashes
      dup.to_backslashes!
    end
    
    ##
    #
    def to_backslashes!
      tr!('/', '\\')
      self
    end
    
    ##
    #
    def capitalize_first!
      JABA.error("Cannot capitalize empty string") if empty?
      self[0] = self[0].chr.upcase
      self
    end

    ##
    #
    def capitalize_first
      dup.capitalize_first!
    end

    ##
    #
    def ensure_end_with!(str)
      if empty?
        replace(str)
      else
        if !end_with?(str)
          self << str
        end
      end
      self
    end

    ##
    #
    def ensure_end_with(str)
      dup.ensure_end_with!(str)
    end

    ##
    #
    def quote!(quote_char = '"')
      if empty?
        replace "#{quote_char}#{quote_char}"
      elsif !(start_with?(quote_char) && end_with?(quote_char))
        insert(0, quote_char)
        self << quote_char
      end
      self
    end

    ##
    # Quote if string contains a space or a macro.
    #
    def vs_quote!
      quote! if self =~ / |\$\(/
      self
    end

    ##
    # Used when generating code example blocks in reference manual.
    #
    def split_and_trim_leading_whitespace
      bg = block_given?
      lines = split("\n")
      lines.shift if lines[0].empty?
      lines.last.rstrip!
      lines.pop if lines.last.empty?

      if lines[0] =~ /^(\s+)/
        lw = Regexp.last_match(1)
        lines.each do |l|
          result = l.delete_prefix!(lw)
          yield result if bg
        end
      else
        lines.each{|l| yield l} if bg
      end
      lines
    end
    
    # Convert all variables specified as $(cpp#varname) (which themselves reference attribute names) into markdown links
    # eg [$(cpp#varname)](#cpp-varname).
    #
    def to_markdown_links
      gsub(/(\$\((.*?)\))/) do
        "[#{$1}](##{$2.sub('#', '-')})"
      end
    end

    ##
    #
    def wrap(...)
      dup.wrap!(...)
    end

    ##
    #
    def wrap!(max_width, prefix: nil, trim_leading_prefix: false)
      indent = prefix ? prefix.size : 0
      width = max_width - indent
      eol = end_with?("\n")
      gsub!(/(.{1,#{width}})( +|$)\n?|(.{#{width}})/) do
        "#{prefix}#{$1}#{$3}\n"
      end
      chop! if (!eol && end_with?("\n"))
      if trim_leading_prefix
        sub!(prefix, '')
      end
      self
    end

    ##
    # Turn eg "C:/projects/GitHub/jaba/lib/jaba/jdl_api/jdl_common.rb:11:in `fail'"
    # into "C:/projects/GitHub/jaba/lib/jaba/jdl_api/jdl_common.rb:11"
    #
    def clean_backtrace
      sub(/:in .*/, '')
    end

    ##
    #
    def to_escaped_xml
      gsub(/["'&<>\n]/) do |match|
        case match
        when '"'
          '&quot;'
        when "'"
          '&apos;'
        when '&'
          '&amp;'
        when '<'
          '&lt;'
        when '>'
          '&gt;'
        when "\n"
          '&#x0D;&#x0A;'
        end
      end
    end

  end

  ##
  #
  refine Array do
  
    ##
    #
    def sort_topological!(by = nil, &each_child_block)
      each_node = lambda {|&b| each(&b) }
      each_child = if by
        lambda {|n, &b| n.send(by).each(&b)}
      else
        each_child_block
      end
      result = []
      TSort.each_strongly_connected_component(each_node, each_child) do |c|
        if c.size == 1
          result << c.first
        else
          JABA.error("#{c.first.describe} contains a cyclic dependency", errobj: c.first)
        end
      end
      replace(result)
    end

    ##
    #
    def sort_no_case!
      sort!{|x, y| x.to_s.casecmp(y.to_s)}
    end

    ##
    #
    def stable_sort!
      sort_by!.with_index {|x, i| [x, i] }
    end
    
    ##
    #
    def stable_sort_by!
      sort_by!.with_index {|x, i| [yield(x), i] }
    end
    
    ##
    # Joins array for use in msbuild files optionally adding an 'inherit' string. Returns nil if string is empty, unless forced.
    #
    def vs_join(separator: ';', inherit: nil, force: false)
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

    ##
    # Joins array elements (paths) into a separted string with all the necessary quoting applied and
    # convert to backslashes. Returns nil if array is empty, unless forced.
    #
    def vs_join_paths(**args)
      map(&:vs_quote!).vs_join(**args)&.to_backslashes!
    end

    ##
    # Used when generating reference manual.
    #
    def make_sentence
      s = String.new
      each do |l|
        s.concat(l.capitalize_first)
        s.ensure_end_with!('. ')
      end
      s
    end

  end

  ##
  #
  refine Hash do

    ##
    # Appends value to array referenced by key, creating array if it does not exist. Value being passed in can be a
    # single value or array. Existing key can be optionally cleared.
    #
    def push_value(key, value, clear: false)
      v = self[key] = fetch(key, [])
      v.clear if clear
      value.array? ? v.concat(value) : v << value
      self
    end
    
  end

  refine Thread::Backtrace::Location do
    
    ##
    # Formats source location for use in user level messages.
    #
    def describe(style: :basename, line: true)
      base = case style
      when :absolute
        path
      when :basename
        path.basename
      when :rel_src_root
        path.relative_path_from(JABA.jaba_install_dir)
      else
        JABA.error("Unsupported style '#{style}'")
      end
      line ? "#{base}:#{lineno}" : base
    end

  end

end
