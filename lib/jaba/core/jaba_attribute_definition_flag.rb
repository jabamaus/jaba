# frozen_string_literal: true

##
#
module JABA

  using JABACoreExt

  ##
  #
  class JabaAttributeDefinitionFlag

    attr_reader :services

    ##
    #
    def id
    end

    ##
    #
    def title
    end

    ##
    #
    def notes
    end

    ##
    #
    def compatible?
      true
    end

  end

  ##
  #
  class JabaAttributeDefinitionFlagRequired < JabaAttributeDefinitionFlag

    ##
    #
    def id
      :required
    end

    ##
    #
    def title
      'TODO'
    end

    ##
    #
    def notes
      'Specifies that the definition writer must supply a value for this attribute'
    end

    ##
    #
    def compatible?(attr_def)
      if attr_def.default_set?
        services.jaba_error(':required can only be specified if no default specified')
      end
    end

  end
  
  ##
  #
  class JabaAttributeDefinitionFlagReadOnly < JabaAttributeDefinitionFlag

    ##
    #
    def id
      :read_only
    end

    ##
    #
    def title
      'TODO'
    end

    ##
    #
    def notes
      'Specifies that the attribute can only be read and not set from user definitions. The value will be initialised inside Jaba'
    end

    ##
    #
    def compatible?(attr_def)
      if attr_def.type_id == :reference
        services.jaba_warning('Reference attribute does not need to be flagged with :read_only as they always are')
      end
    end
  end
  
  ##
  #
  class JabaAttributeDefinitionFlagExpose < JabaAttributeDefinitionFlag

    ##
    #
    def id
      :expose
    end

    ##
    #
    def title
      'TODO'
    end

    ##
    #
    def notes
      'Attributes flagged with :expose that are in a type that is then referenced by another type will have their attribute ' \
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
  class JabaAttributeDefinitionFlagAllowDupes < JabaAttributeDefinitionFlag

    ##
    #
    def id
      :allow_dupes
    end

    ##
    #
    def title
      'TODO'
    end

    ##
    #
    def notes
      'Allows array attributes to contain duplicates. If not specified duplicates are stripped'
    end

    ##
    #
    def compatible?(attr_def)
      if !attr_def.array?
        services.jaba_error(':allow_dupes is only allowed on array attributes')
      end
    end

  end
  
  ##
  #
  class JabaAttributeDefinitionFlagNoSort < JabaAttributeDefinitionFlag

    ##
    #
    def id
      :no_sort
    end

    ##
    #
    def title
      'TODO'
    end

    ##
    #
    def notes
      'Allows array attributes to remain in the order they are set in. If not specified arrays are sorted'
    end

    ##
    #
    def compatible?(attr_def)
      if !attr_def.array?
        services.jaba_error(':no_sort is only allowed on array attributes')
      end
    end

  end
  
  # TODO: use this
  class JabaAttributeDefinitionFlagNoCheckExist < JabaAttributeDefinitionFlag

    ##
    #
    def id
      :no_check_exist
    end

    ##
    #
    def title
      'TODO'
    end

    ##
    #
    def notes
      'Use with file, dir or path attributes to disable checking if the path exists on disk, eg if it will get generated'
    end

    ##
    #
    def compatible?(attr_def)
      if attr_def.type_id != :file && attr_def.type_id != :dir
        services.jaba_error(":no_check_exist can only be used with :file and :dir attribute types")
      end
    end

  end
  
end
