require 'pry'
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

    VERIFY_SLEEP_PERIOD = 1.freeze
    VERIFY_RETRIES = 3.freeze

    def initialize(driver, dimension = nil)
      @driver = driver
      @dimension = setup_dimension(dimension)
    end

    def extract_viewport_from_browser!
      @dimension = extract_viewport_from_browser
    end

    def extract_viewport_from_browser
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

    alias_method :viewport_size, :extract_viewport_from_browser

    def set
      # Before resizing the window, set its position to the upper left corner (otherwise, there might not be enough
      # "space" below/next to it and the operation won't be successful).
      browser_to_upper_left_corner

      retries_left = VERIFY_RETRIES

      until retries_left == 0 || viewport_size == @dimension do
        resize_browser ViewportSize.required_size(
            browser_size: browser_size,
            current_viewport_size: extract_viewport_from_browser,
            required_viewport_size: @dimension
        )
        sleep VERIFY_SLEEP_PERIOD
        retries_left -= 1
      end

      if retries_left == 0
        err_msg = "Failed to resize browser to #{@dimension.values} (current size: #{viewport_size.values})"
        Applitools::EyesLogger.error(err_msg)
        raise Applitools::TestFailedError.new(err_msg)
      end
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
      return Applitools::Base::Dimension.for(dimension) if dimension.respond_to?(:width) & dimension.respond_to?(:height)
      return Applitools::Base::Dimension.new(
          dimension[:width],
          dimension[:height]
      ) if dimension.is_a?(Hash) && (dimension.keys & [:width, :height]).size == 2

      raise ArgumentError,
            "expected #{@dimension.inspect}:#{@dimension.class} to respond to #width and #height, or be  a hash with these keys."
    end

    class << self
      def required_size(options)
        unless options[:browser_size].is_a?(Applitools::Base::Dimension) &&
               options[:current_viewport_size].is_a?(Applitools::Base::Dimension) &&
               options[:required_viewport_size].is_a?(Applitools::Base::Dimension)

          raise ArgumentError,
                "expected #{options.inspect}:#{options.class} to be a hash with keys"\
                " :browser_size, :current_viewport_size, :required_viewport_size"
        end
        options[:browser_size] - options[:current_viewport_size] + options[:required_viewport_size]
      end
    end
  end
end
