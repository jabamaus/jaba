# frozen_string_literal: true

##
#
module JABA

  using JABACoreExt

  ##
  #
  class JabaAttrDefFlag

    attr_reader :services
    attr_reader :id
    attr_reader :title
    attr_reader :notes

    ##
    #
    def initialize(id, title)
      @id = id
      @title = title
      @notes = nil
    end

    ##
    #
    def describe
      "#{@id.inspect} attribute definition flag"
    end

    ##
    #
    def post_create
      JABA.error("id must be specified") if id.nil?
      JABA.error("#{describe} must have a title") if title.nil?
      @id.freeze
      @title.freeze
      @notes.freeze
    end

    ##
    #
    def compatible?
      true
    end

  end

  ##
  #
  class JabaAttrDefFlagRequired < JabaAttrDefFlag

    ##
    #
    def initialize
      super(:required, 'Force user to supply a value')
      @notes = 'Specifies that the definition writer must supply a value for this attribute'
    end

    ##
    #
    def compatible?(attr_def)
      if attr_def.default_set?
        JABA.error("#{describe} can only be specified if no default specified")
      end
    end

  end
  
  ##
  #
  class JabaAttrDefFlagReadOnly < JabaAttrDefFlag

    ##
    #
    def initialize
      super(:read_only, 'Prevents user from writing to value')
      @notes = 'Specifies that the attribute can only be read and not set from user definitions. The value will be initialised inside Jaba'
    end

    ##
    #
    def compatible?(attr_def)
      if attr_def.type_id == :node_ref
        services.jaba_warn('Object reference attribute does not need to be flagged with :read_only as they always are')
      end
    end

  end
  
  ##
  #
  class JabaAttrDefFlagExpose < JabaAttrDefFlag

    ##
    #
    def initialize
      super(:expose, 'Access strategy')
      @notes = 'Attributes flagged with :expose that are in a type that is then referenced by another type will have their attribute ' \
      'name automatically imported as a read only property. An example of this is the windows? attribute in :platform type'
    end

    ##
    #
    def compatible?(attr_def)
      true # TODO
    end

  end
  
  ##
  #
  class JabaAttrDefFlagAllowDupes < JabaAttrDefFlag

    ##
    #
    def initialize
      super(:allow_dupes, 'Array duplicates strategy')
      @notes = 'Allows array attributes to contain duplicates. If not specified duplicates are stripped'
    end

    ##
    #
    def compatible?(attr_def)
      if !attr_def.array?
        JABA.error("#{describe} is only allowed on array attributes")
      end
    end

  end
  
  ##
  #
  class JabaAttrDefFlagNoSort < JabaAttrDefFlag

    ##
    #
    def initialize
      super(:no_sort, 'Array sorting strategy')
      @notes = 'Allows array attributes to remain in the order they are set in. If not specified arrays are sorted'
    end

    ##
    #
    def compatible?(attr_def)
      if !attr_def.array?
        JABA.error("#{describe} is only allowed on array attributes")
      end
    end

  end
  
  # TODO: use this
  class JabaAttrDefFlagNoCheckExist < JabaAttrDefFlag

    ##
    #
    def initialize
      super(:no_check_exist, 'Disable path exist check')
      @notes = 'Use with :file or :dir attributes to disable checking if the path exists on disk, eg if it will get generated'
    end

    ##
    #
    def compatible?(attr_def)
      if attr_def.type_id != :file && attr_def.type_id != :dir
        JABA.error("#{describe} can only be used with :file and :dir attribute types")
      end
    end

  end

  ##
  #
  class JabaAttrDefFlagDelayEvaluation < JabaAttrDefFlag

    ##
    #
    def initialize
      super(:delay_evaluation, 'Delay evaluation of block')
      @notes = 'Use with :node attribute to stop the associated block from being executed immediately. Instead ' \
        'the block will be stored and the generator back end will be responsible for executing it. Enables the ' \
        'generator to pass input in and to execute multiple times with different inputs'
    end

    ##
    #
    def compatible?(attr_def)
      if attr_def.type_id != :node
        JABA.error("#{describe} can only be used with :node attribute type")
      end
    end

  end
  
end
