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
      Pathname.new(self).relative_path_from(base).to_s
    end
  
    ##
    # Returns true if string is a windows or unix style absolute path.
    #
    def absolute_path?
      self =~ /^(\/)|([A-Za-z]:)/ ? true : false
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
    def sort_topological!(children)
      replace(JABA::TSorter.new(self, children).sort)
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
    
  end
  
end
