module Applitools::Selenium
  # @!visibility private
  class ElementPositionProvider
    extend Forwardable
    def_delegators 'Applitools::EyesLogger', :logger, :log_handler, :log_handler=

    def initialize(executor, passed_element)
      Applitools::Core::ArgumentGuard.not_nil 'executor', executor
      Applitools::Core::ArgumentGuard.not_nil 'passed_element', passed_element
      self.driver = executor
      self.element = passed_element
      self.element = Applitools::Selenium::Element.new(driver, element) unless
          element.is_a? Applitools::Selenium::Element
    end

    def current_position
      logger.info 'current_position() has called.'
      result = Applitools::Core::Location.for element.scroll_left, element.scroll_top
      logger.info "Current position is #{result}"
      result
    end

    def entire_size
      logger.info 'entire_size()'
      result = Applitools::Core::RectangleSize.new(element.scroll_width, element.scroll_height)
      logger.info "Entire size: #{result}"
      result
    end

    def state
      current_position
    end

    def restore_state(value)
      self.position = value
    end

    def position=(location)
      logger.info "Scrolling element to #{location}"
      element.scroll_to location
      logger.info 'Done scrolling element!'
    end

    private

    attr_accessor :element, :driver
  end
end
