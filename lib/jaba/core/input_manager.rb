# frozen_string_literal: true

##
#
module JABA

  using JABACoreExt

  ##
  #
  class InputManager

    ##
    #
    def initialize(services)
      @services = services

      @argv = services.input.argv
      if !@argv.array?
        jaba_error("'argv' must be an array")
      end
    end

    ##
    #
    def process
      @input_node = services.input_singleton
    end

  end

end
