module JABA

  class Registry
    def self.instance = @@registry ||= new
    def initialize
      @attr_types = []
      @attr_type_lookup = {}
      @attr_flags = []
      @attr_flag_lookup = {}
      
      attr_types = JABA.constants(false).select{|c| c =~ /^AttributeType./}
      attr_types.each do |c|
        klass = JABA.const_get(c)
        at = klass.new
        @attr_types << at
        @attr_type_lookup[at.id] = at
      end
      @attr_types.sort_by!(&:id)
    end

    def lookup_attr_type(id, fail_if_not_found: true)
      at = @attr_type_lookup[id]
      if at.nil? && fail_if_not_found
        JABA.error("'#{id.inspect_unquoted}' attribute type not found")
      end
      at
    end

    def self.define_attr_flag(...) = instance.define_attr_flag(...)

    def define_attr_flag(name, &block)
      fd = AttributeFlag.new(name)
      FlagDefinitionAPI.execute(fd, &block) if block
      @attr_flags << fd
      @attr_flag_lookup[name] = fd
    end

    def lookup_attr_flag(name, fail_if_not_found: true)
      af = @attr_flag_lookup[name]
      if af.nil? && fail_if_not_found
        JABA.error("'#{name.inspect_unquoted}' attribute flag not found")
      end
      af
    end
  end
end