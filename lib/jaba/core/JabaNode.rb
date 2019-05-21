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
          @attr_def.api_eval(value, &vv)
        rescue JabaError => e
          @services.jaba_error("'#{@attr_def.id}' attribute failed validation: #{e.raw_message}", callstack: e.backtrace)
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
  def set(values, api_call_line=nil, *args, prefix: nil, postfix: nil, exclude: nil, **key_value_args, &block)
    @api_call_line = api_call_line
    
    Array(values).each do |v|
      elem = Attribute.new(@services, @attr_def)
      v = apply_pre_post_fix(prefix, postfix, v)
      elem.set(v, api_call_line, *args, **key_value_args, &block)
      @elems << elem
      @set = true
    end
    
    if exclude
      Array(exclude).each do |e|
        @excludes << apply_pre_post_fix(prefix, postfix, e)
      end
    end
  end
  
  ##
  #
  def apply_pre_post_fix(pre, post, val)
    if (pre or post)
      if !val.is_a?(String)
        @services.jaba_error('prefix/postfix option can only be used with arrays of strings', callstack: api_call_line)
      end
      "#{pre}#{val}#{post}"
    else
      val
    end
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
    if !@attr_def.has_flag?(:allow_dupes)
      if (@elems.uniq!(&:get) and warn)
        @services.jaba_warning("'#{id}' array attribute contains duplicates", callstack: api_call_line)
      end
    end
    if !@attr_def.has_flag?(:unordered)
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
class JabaNode < JabaAPIObject

  attr_reader :id
  attr_reader :attributes
  attr_reader :generator_hooks
  ##
  #
  def initialize(services, jaba_type, id, source_location)
  def initialize(services, jaba_type, id, attrs_mask, parent, source_location)
    super(services, services.jaba_node_api)
    @jaba_type = jaba_type
    @id = id
    @parent = parent
    @source_location = source_location
    
    @attributes = []
    @attribute_lookup = {}
    @attr_def_mask = attrs_mask ? Array(attrs_mask).map{|id| @jaba_type.get_attr_def(id)} : nil
    @generator_hooks = []
    
    attr_defs = @attr_def_mask ? @attr_def_mask : @jaba_type.attribute_defs
    attr_defs.each do |attr_def|
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
  def get_attr(attr_id, fail_if_not_found: true)
    a = @attribute_lookup[attr_id]
    if (!a and fail_if_not_found)
      @services.jaba_error("'#{attr_id}' attribute not found in '#{id}'")
    end
    a
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
    @generator_hooks << block
  end
  
  ##
  #
  def save_file(filename, content, eol)
    @services.save_file(filename, content, eol)
  end
  
  ##
  # If an attribute set operation is being performed, args contains the 'value' and then a list optional symbols which act as options.
  # eg my_attr 'val', :export, :exclude would make args equal to ['val', :opt1, :opt2]. If however the value being passed in is
  # an array it could be eg [['val1', 'val2'], :opt1, :opt2].
  #  
  def handle_attr(id, api_call_line, *args, **key_value_args, &block)
    if @attr_def_mask
      if @attr_def_mask.none?{|ad| ad.id == id} # TODO: doesn't work with boolean accessor
        return nil
      end
    end
    
    getter = (args.empty? and key_value_args.empty?)
    a = get_attr(id, fail_if_not_found: false)

    if !a
      raw_id = id.to_s.chomp('?').to_sym # Remove any trailing '?' (used with boolean attrs) to get the raw name
      a2 = get_attr(raw_id, fail_if_not_found: false)
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
