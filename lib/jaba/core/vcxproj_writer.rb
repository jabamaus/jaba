# frozen_string_literal: true

module JABA
  
  ##
  #
  class VsprojWriter < StringWriter
    
    ##
    #
    def initialize
    end
    
    ##
    #
    def write
      write "\uFEFF<?xml version=\"1.0\" encoding=\"utf-8\"?>"
      write "<Project DefaultTargets=\"Build\" ToolsVersion=\"#{tools_version}\" " \
            'xmlns=\"http://schemas.microsoft.com/developer/msbuild/2003\">'
      do_write
      write_raw '</Project>'
    end
    
    private
    
    ##
    #
    def tools_version
      'TODO'
    end
    
  end
  
  ##
  #
  class VcxprojWriter < VsprojWriter
    
    ##
    #
    def initialize
      super
    end
    
    ##
    #
    def do_write
    end
    
  end
  
end
