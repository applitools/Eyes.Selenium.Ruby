module Applitools::Selenium
  class Element < SimpleDelegator
    TRACE_PREFIX = 'EyesWebElement'.freeze

    def initialize(driver, element)
      super(element)

      @driver = driver
    end

    def web_element
      @web_element ||= __getobj__
    end

    def click
      current_control = region
      offset = current_control.middle_offset
      @driver.user_inputs << Applitools::Base::MouseTrigger.new(:click, current_control, offset)

      web_element.click
    end

    def inspect
      TRACE_PREFIX + web_element.inspect
    end

    def ==(other)
      # If comparing two Applitools::Selenium::Element, compare their wrapped elements
      return web_element == other.web_element if other.is_a?(self.class)

      other.is_a?(web_element.class) && web_element == other
    end
    alias eql? ==

    def send_keys(*args)
      current_control = region
      Selenium::WebDriver::Keys.encode(args).each do |key|
        @driver.user_inputs << Applitools::Base::TextTrigger.new(key.to_s, current_control)
      end

      web_element.send_keys(*args)
    end
    alias send_key send_keys

    def region
      point = location
      left = point.x
      top = point.y
      width = 0
      height = 0

      begin
        dimension = size
        width = dimension.width
        height = dimension.height
      rescue => e
        # Not supported on all platforms.
        Applitools::EyesLogger.error("Failed extracting size using JavaScript: (#{e.message})")
      end

      if left < 0
        width = [0, width + left].max
        left = 0
      end

      if top < 0
        height = [0, height + top].max
        top = 0
      end

      Applitools::Base::Region.new(left, top, width, height)
    end

    def find_element(*args)
      self.class.new driver, super
    end

    def find_elements(*args)
      super(*args).map { |e| self.class.new driver, e }
    end

    private

    attr_reader :driver
  end
end
