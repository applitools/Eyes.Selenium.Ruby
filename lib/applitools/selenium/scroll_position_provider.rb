module Applitools::Selenium
  class ScrollPositionProvider

    def initialize(executor)
      self.executor = executor
    end

    ##
    # The scroll position of the current frame
    #
    #
    #

    def current_position
      logger.info 'current_position()'
      result = Applitools::Utils::EyesSeleniumUtils.current_scroll_position(executor)
      logger.info "Current position: #{result}"
    rescue #TODO: clarify class of the exception
      raise 'Failed to extract current scroll position!'
    end

    def state

    end

    def restore_state

    end

    def position=(value)

    end

    private
    attr_accessor :executor

  end
end