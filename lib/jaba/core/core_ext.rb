# frozen_string_literal: true

require 'pathname'

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
      class_eval("def #{attr}(&block) ; block_given? ? @#{attr} = block : @#{attr} ; end", __FILE__, __LINE__)
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
    
  end

  ##
  #
  refine String do

    ##
    #
    def basename
      File.basename(self)
    end
    
    ##
    #
    def capitalize_first!
      self[0] = self[0].chr.upcase
      self
    end

    ##
    #
    def capitalize_first
      dup.capitalize_first!
    end
    
    ##
    # Cleans path by removing all extraneous ., .. and slashes. Supports windows and UNIX style absolute paths
    # and UNC paths.
    #
    def cleanpath
      result = []
      
      split_path.each do |part|
        if part == '..'
          case result.last
          when '..', nil
            result.push('..')
          else
            result.pop
          end
        else
          result.push(part)
        end
      end
      
      path = result.join('/')

      # Preserve leading slash(es) if its a UNC path or UNIX style absolute path
      #
      if start_with?('//')
        path.insert(0, '//')
      elsif start_with?('/')
        path.insert(0, '/')
      elsif path.empty?
        path = '.'
      elsif path[1] == ':'
        path[0] = path[0].chr.upcase # Capitalise drive letter
      end
      
      path
    end

    ##
    #
    def cleanpath!
      replace(cleanpath)
    end

    ##
    # Helper method that splits string on forward or backslashes, deleting any resulting blanks and uneeded '.'.
    # Does not preserve absolute UNIX paths or UNC paths, which the calling method is expected to handle.
    #
    def split_path
      parts = split(/[\/\\]/)
      parts.delete('.')
      parts.delete('')
      parts
    end

    ##
    #
    def to_forward_slashes
      dup.to_forward_slashes!
    end
    
    ##
    #
    def to_forward_slashes!
      tr!('\\', '/')
      self
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
    def relative_path_from(base)
      # TODO: SLOW. 
      Pathname.new(self).relative_path_from(base).to_s
    end
  
    ##
    # Returns true if string is a windows or unix style absolute path.
    #
    def absolute_path?
      self[0].chr == '/' || self[0].chr == '\\' || (size > 1 && self[1].chr == ':')
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
          e = TSort::Cyclic.new
          e.instance_variable_set(:@err_obj, c.first)
          raise e
        end
      end
      replace(result)
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
      value.is_a?(Array) ? v.concat(value) : v << value
      self
    end
    
  end

end
