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
    def is_a_block?
      is_a?(Proc)
    end

    ##
    #
    def profile(enabled: true)
      raise 'block expected' if !block_given?

      if !enabled
        yield
        return
      end
      
      begin
        puts 'Invoking ruby-prof...'
        require 'ruby-prof'
        RubyProf.start
        yield
      ensure
        result = RubyProf.stop
        file = File.expand_path('jaba.profile')
        str = String.new
        puts "Write profiling results to #{file}..."
        [RubyProf::FlatPrinter, RubyProf::GraphPrinter].each do |p|
          printer = p.new(result)
          printer.print(str)
        end
        IO.write(file, str)
      end
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
    #
    def cleanpath
      # TODO: SLOW. 
      Pathname.new(self).cleanpath.to_s
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
      self =~ /^(\/)|([A-Za-z]:)/ ? true : false
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
  
end
