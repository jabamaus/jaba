module JABA

##
#
class AttributeBase

  attr_reader :attr_def
  attr_reader :api_call_line
  
  ##
  #
  def initialize(services, attr_def)
    @services = services
    @attr_def = attr_def
    @api_call_line = nil
    @set = false
  end
  
  ##
  #
  def id
    @attr_def.id
  end
  
  ##
  #
  def set?
    @set
  end
  
  ##
  #
  def required?
    @attr_def.has_flag?(:required)
  end
  
end

##
#
class Attribute < AttributeBase

  ##
  #
  def initialize(services, attr_def)
    super
    @value = nil
    d = @attr_def.default
    if (!d.nil? and !d.is_a?(Proc))
      set(d)
    end
  end
  
  ##
  #
  def get
    @value
  end
  
  ##
  #
  def set(value, api_call_line=nil, *args, **key_value_args, &block)
    @api_call_line = api_call_line
    if value.is_a?(Array)
      @services.jaba_error("'#{@attr_def.id}' attribute cannot accept an array as not flagged with :array")
    end
    if api_call_line
      vv = @attr_def.type_obj.value_validator
      if vv
        begin
          instance_exec(value, &vv)
        rescue => e
          @services.jaba_error("'#{@attr_def.id}' attribute failed validation: #{e.message.capitalize_first}", callstack: e.backtrace)
        end
      end
    end
    @value = value
    @set = true
  end
  
  ##
  #
  def clear
    @value = nil
    d = @attr_def.default
    if (!d.nil? and !d.is_a?(Proc))
      @value = d
    end
  end
  
  ##
  #
  def <=>(other)
    if @value.respond_to?(:casecmp) # Subtlety here. Don't check if responds to to_s as would incorrectly sort numbers by string.
      @value.to_s.casecmp(other.get.to_s)
    else
      @value <=> other.get
    end
  end
  
  ##
  #
  def process_flags(warn: true)
  end
  
end

##
#
class AttributeArray < AttributeBase
  
  ##
  #
  def initialize(services, attr_def)
    super
    @elems = []
    @excludes = []
  end
  
  ##
  #
  def get
    @elems.map{|e| e.get}
  end
  
  ##
  #
  def set(values, api_call_line=nil, *args, prefix: nil, suffix: nil, exclude: nil, **key_value_args, &block)
    @api_call_line = api_call_line
    Array(values).each do |v|
      elem = Attribute.new(@services, @attr_def)
      
      if (prefix or suffix)
        if !v.is_a?(String)
          @services.jaba_error('prefix/suffix option can only be used with arrays of strings', callstack: api_call_line)
        end
        v = "#{prefix}#{v}#{suffix}"
      end
      
      elem.set(v, api_call_line, *args, **key_value_args, &block)
      
      @elems << elem
      @set = true
    end
    
    @excludes.concat(Array(exclude)) if exclude
  end
  
  ##
  #
  def clear
    @elems.clear
  end
  
  ##
  #
  def process_flags(warn: true)
    if @excludes
      @elems.delete_if do |e|
        @excludes.any? do |ex|
          val = e.get
          if ex.is_a?(Proc)
            ex.call(val)
          elsif ex.is_a?(Regexp)
            if !val.is_a?(String)
              @services.jaba_error('exclude regex can only operate on strings', callstack: e.api_call_line)
            end
            val.match(ex)
          else
            ex == val
          end
        end
      end
    end
    if (!@attr_def.has_flag?(:allow_dupes) and attr_def.type_obj.supports_uniq?)
      if (@elems.uniq!(&:get) and warn)
        @services.jaba_warning("'#{id}' array attribute contains duplicates", callstack: api_call_line)
      end
    end
    if (!@attr_def.has_flag?(:unordered) and attr_def.type_obj.supports_sort?)
      begin
        @elems.sort!
      rescue
        @services.jaba_error("Failed to sort #{id}. Might be missing <=> operator", callstack: api_call_line)
      end
    end
  end
  
end

##
#
class JabaObject

  attr_reader :id
  
  ##
  #
  def initialize(services, jaba_type, id, source_location)
    @services = services
    @jaba_type = jaba_type
    @id = id
    @source_location = source_location
    
    @attributes = []
    @attribute_lookup = {}
    
    @generators = []

    @jaba_type.each_attr do |attr_def|
      a = attr_def.has_flag?(:array) ? AttributeArray.new(services, attr_def) : Attribute.new(services, attr_def)
      if attr_def.type == :bool
        @attribute_lookup["#{attr_def.id}?".to_sym] = a
      end
      @attribute_lookup[attr_def.id] = a
      @attributes << a
    end
  end
  
  ##
  #
  def get_attr(id)
  # TODO: fail id not found
    @attribute_lookup[id]
  end
  
  ##
  #
  def post_create
    @attributes.each do |a|
      if (a.required? and !a.set?)
        @services.jaba_error("'#{a.id}' attribute requires a value", callstack: [@source_location.join(':'), a.attr_def.source_location.join(':')]) # TODO: wrap up nicer
      end
      a.process_flags(warn: true)
    end
  end
  
  ##
  #
  def define_generator(&block)
    @generators << block
  end
  
  ##
  #
  def call_generators
    # Call generators defined per-type
    #
    @jaba_type.generators.each do |block|
      instance_eval(&block)
    end
    
    # Call generators defined per-object
    #
    @generators.each do |block|
      block.call
    end
  end
  
  ##
  #
  def save_file(filename, content, eol)
    @services.save_file(filename, content, eol)
  end
  
  ##
  #
  def include_shared(ids, args)
    ids.each do |id|
      df = @services.get_definition(:shared, id, fail_if_not_found: false)
      if !df
        @services.jaba_error("Shared definition '#{id}' not found")
      end
      
      n_expected_args = df.block.arity
      n_supplied_args = args ? Array(args).size : 0
      
      if (n_supplied_args != n_expected_args)
        @services.jaba_error("shared definition '#{id}' expects #{n_expected_args} arguments but #{n_supplied_args} were passed")
      end
      
      if args.nil?
        @services.jaba_object_api.instance_eval(&df.block)
      else
        @services.jaba_object_api.instance_exec(*args, &df.block)
      end
    end
  end
  
  ##
  # If an attribute set operation is being performed, args contains the 'value' and then a list optional symbols which act as options.
  # eg my_attr 'val', :export, :exclude would make args equal to ['val', :opt1, :opt2]. If however the value being passed in is
  # an array it could be eg [['val1', 'val2'], :opt1, :opt2].
  #  
  def handle_attr(id, api_call_line, *args, **key_value_args, &block)
    getter = (args.empty? and key_value_args.empty?)
    a = get_attr(id)

    if !a
      raw_id = id.to_s.chomp('?').to_sym # Remove any trailing '?' (used with boolean attrs) to get the raw name
      a2 = get_attr(raw_id)
      if a2
        @services.jaba_error("'#{raw_id}' attribute is not of type :bool")
      else
        @services.jaba_error("'#{raw_id}' attribute not defined")
      end
    end
    
    if getter
      a.get
    else
      # Get the value by popping the first element from the front of the list. This could yield a single value or an array,
      # depending on what the user passed in (see comment at top of this method.
      #
      value = args.shift
      a.set(value, api_call_line, *args, **key_value_args, &block)
    end
  end
  
  ##
  #
  def method_missing(attr_id, *args, **key_value_args, &block)
    handle_attr(attr_id, nil, *args, **key_value_args, &block)
  end
  
  ##
  #
  def wipe_attrs(ids)
    ids.each do |id|
      if !id.is_a?(Symbol)
        @services.jaba_error("'#{id}' must be specified as a symbol")
      end
      get_attr(id).clear
    end
  end
  
end

end
