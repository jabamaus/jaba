module JABA

##
#
class AttributeBase

  attr_reader :attr_def
  
  ##
  #
  def initialize(services, attr_def)
    @services = services
    @attr_def = attr_def
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
  def set(value, from_definitions=false, *options, prefix: nil, suffix: nil, **key_value_options, &block)
    if from_definitions
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
  end
  
  ##
  #
  def get
    @elems.map{|e| e.get}
  end
  
  ##
  #
  def set(values, from_definitions=false, *options, **key_value_options, &block)
    Array(values).each do |v|
      elem = Attribute.new(@services, @attr_def)
      elem.set(v, from_definitions, *options, **key_value_options, &block)
      @elems << elem
    end
    @set = true
  end
  
  ##
  #
  def process_flags(warn: true)
    if (!@attr_def.has_flag?(:allow_dupes) and attr_def.type_obj.supports_uniq?)
      if (@elems.uniq!(&:get) and warn)
        @services.jaba_warning("'#{id}' array attribute contains duplicates")
      end
    end
    if (!@attr_def.has_flag?(:unordered) and attr_def.type_obj.supports_sort?)
      begin
        @elems.sort!
      rescue
        @services.jaba_error("Failed to sort #{id}. Might be missing <=> operator")
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
  #
  def handle_attr(id, called_from_definitions, *args, **key_value_args, &block)
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
      a.set(args.shift, called_from_definitions, *args, **key_value_args, &block)
    end    
  end
  
  ##
  #
  def method_missing(attr_name, *args, **key_value_args, &block)
    handle_attr(attr_name, true, *args, **key_value_args, &block)
  end
  
end

end
