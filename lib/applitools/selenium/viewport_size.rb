module Applitools::Selenium
  class ViewportSize
    JS_GET_VIEWPORT_SIZE = <<-JS.freeze
       return (function() {
         var height = undefined;
         var width = undefined;
         if (window.innerHeight) {height = window.innerHeight;}
         else if (document.documentElement && document.documentElement.clientHeight)
         {height = document.documentElement.clientHeight;}
         else { var b = document.getElementsByTagName('body')[0];
            if (b.clientHeight) {height = b.clientHeight;}
         };

         if (window.innerWidth) {width = window.innerWidth;}
         else if (document.documentElement && document.documentElement.clientWidth)
         {width = document.documentElement.clientWidth;}
         else { var b = document.getElementsByTagName('body')[0];
            if (b.clientWidth) {width = b.clientWidth;}
         };
         return [width, height];
         }());
    JS

    VERIFY_SLEEP_PERIOD = 1
    VERIFY_RETRIES = 3
    BROWSER_SIZE_CALCULATION_RETRIES = 2

    def initialize(driver, dimension = nil)
      @driver = driver
      @dimension = dimension.nil? ? nil : setup_dimension(dimension)
    end

    def size
      @dimension
    end

    def extract_viewport_size!
      @dimension = extract_viewport_from_browser
    end

    alias extract_viewport_from_browser! extract_viewport_size!

    def extract_viewport_size
      width = nil
      height = nil
      begin
        width, height = @driver.execute_script(JS_GET_VIEWPORT_SIZE)
      rescue => e
        Applitools::EyesLogger.error "Failed extracting viewport size using JavaScript: (#{e.message})"
      end
      if width.nil? || height.nil?
        Applitools::EyesLogger.info 'Using window size as viewport size.'

        width, height = *browser_size.values.map(&:ceil)

        if @driver.landscape_orientation? && height > width
          width, height = height, width
        end
      end

      Applitools::Base::Dimension.new(width, height)
    end

    alias viewport_size extract_viewport_size
    alias extract_viewport_from_browser extract_viewport_size

    def set
      Applitools::EyesLogger.debug "Set viewport size #{@dimension}"
      # Before resizing the window, set its position to the upper left corner (otherwise, there might not be enough
      # "space" below/next to it and the operation won't be successful).
      browser_to_upper_left_corner

      browser_size_calculation_count = 0
      while browser_size_calculation_count < BROWSER_SIZE_CALCULATION_RETRIES
        unless resize_attempt
          raise Applitools::TestFailedError.new 'Failed to set browser size!' \
            " (current size: #{browser_size})"
        end
        browser_size_calculation_count += 1
        if viewport_size == size
          Applitools::EyesLogger.debug "Actual viewport size #{viewport_size}"
          return
        end
      end
      raise Applitools::TestFailedError.new 'Failed to set viewport size'
    end

    def browser_size
      Applitools::Base::Dimension.for @driver.manage.window.size
    end

    def resize_browser(other)
      @driver.manage.window.size = other
    end

    def browser_to_upper_left_corner
      @driver.manage.window.position = Selenium::WebDriver::Point.new(0, 0)
    rescue Selenium::WebDriver::Error::UnsupportedOperationError => e
      Applitools::EyesLogger.warn "Unsupported operation error: (#{e.message})"
    end

    def to_hash
      @dimension.to_hash
    end

    private

    def setup_dimension(dimension)
      return dimension if dimension.is_a? ::Selenium::WebDriver::Dimension
      return Applitools::Base::Dimension.for(dimension) if dimension.respond_to?(:width) &
          dimension.respond_to?(:height)
      if dimension.is_a?(Hash) && (dimension.keys & [:width, :height]).size == 2
        return Applitools::Base::Dimension.new(
          dimension[:width],
          dimension[:height]
        )
      end
      raise ArgumentError,
        "expected #{@dimension.inspect}:#{@dimension.class} to respond to #width and #height," \
        ' or be  a hash with these keys.'
    end

    # Calculates a necessary browser size to get a requested viewport size,
    # tries to resize browser, yields a block (which should check if an attempt was successful) before each iteration.
    # If the block returns true, stop trying and returns true (resize was successful)
    # Otherwise, returns false after VERIFY_RETRIES iterations

    def resize_attempt
      actual_viewport_size = extract_viewport_size
      Applitools::EyesLogger.debug "Actual viewport size #{actual_viewport_size}"
      required_browser_size = ViewportSize.required_browser_size actual_browser_size: browser_size,
        actual_viewport_size: actual_viewport_size, required_viewport_size: size

      retries_left = VERIFY_RETRIES

      until retries_left.zero?
        return true if browser_size == required_browser_size
        Applitools::EyesLogger.debug "Trying to set browser size to #{required_browser_size}"
        resize_browser required_browser_size
        sleep VERIFY_SLEEP_PERIOD
        Applitools::EyesLogger.debug "Required browser size #{required_browser_size}, " \
          "Current browser size #{browser_size}"
        retries_left -= 1
      end
      false
    end

    class << self
      def required_browser_size(options)
        unless options[:actual_browser_size].is_a?(Applitools::Base::Dimension) &&
            options[:actual_viewport_size].is_a?(Applitools::Base::Dimension) &&
            options[:required_viewport_size].is_a?(Applitools::Base::Dimension)

          raise ArgumentError,
            "expected #{options.inspect}:#{options.class} to be a hash with keys" \
            ' :actual_browser_size, :actual_viewport_size, :required_viewport_size'
        end
        options[:actual_browser_size] - options[:actual_viewport_size] + options[:required_viewport_size]
      end
    end
  end
end
