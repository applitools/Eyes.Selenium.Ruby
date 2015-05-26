module Applitools::Selenium
  class ViewportSize
    JS_GET_VIEWPORT_HEIGHT = (<<-JS).freeze
      return (function() {
        var height = undefined;
        if (window.innerHeight) {
          height = window.innerHeight;
        }
        else if (document.documentElement && document.documentElement.clientHeight) {
          height = document.documentElement.clientHeight;
        } else {
          var b = document.getElementsByTagName("body")[0];
          if (b.clientHeight) {
            height = b.clientHeight;
          }
        }

        return height;
      }());
    JS

    JS_GET_VIEWPORT_WIDTH = (<<-JS).freeze
      return (function() {
        var width = undefined;
        if (window.innerWidth) {
          width = window.innerWidth
        } else if (document.documentElement && document.documentElement.clientWidth) {
          width = document.documentElement.clientWidth;
        } else {
          var b = document.getElementsByTagName("body")[0];
          if (b.clientWidth) {
            width = b.clientWidth;
          }
        }

        return width;
      }());
    JS

    VERIFY_SLEEP_PERIOD = 1.freeze
    VERIFY_RETRIES = 3.freeze

    def initialize(driver, dimension = nil)
      @driver = driver
      @dimension = dimension
    end

    def extract_viewport_width
      @driver.execute_script(JS_GET_VIEWPORT_WIDTH)
    end

    def extract_viewport_height
      @driver.execute_script(JS_GET_VIEWPORT_HEIGHT)
    end

    def extract_viewport_from_browser!
      @dimension = extract_viewport_from_browser
    end

    def extract_viewport_from_browser
      width = nil
      height = nil
      begin
        width  = extract_viewport_width
        height = extract_viewport_height
      rescue => e
        Applitools::EyesLogger.error "Failed extracting viewport size using JavaScript: (#{e.message})"
      end

      if width.nil? || height.nil?
        Applitools::EyesLogger.info 'Using window size as viewport size.'

        width, height = *browser_size.values
        width = width.ceil
        height = height.ceil

        if @driver.landscape_orientation? && height > width
          width, height = height, width
        end
      end

      Applitools::Base::Dimension.new(width, height)
    end

    alias_method :viewport_size, :extract_viewport_from_browser

    def set
      if @dimension.is_a?(Hash) && @dimension.key?(:width) && @dimension.key?(:height)
        # If @dimension is hash of width/height, we convert it to a struct with width/height properties.
        @dimension = Struct.new(:width, :height).new(@dimension[:width], @dimension[:height])
      elsif !@dimension.respond_to?(:width) || !@dimension.respond_to?(:height)
        raise ArgumentError, "expected #{@dimension.inspect}:#{@dimension.class} to respond to #width and #height, or "\
          'be  a hash with these keys.'
      end

      resize_browser(@dimension)
      verify_size(:browser_size)

      cur_viewport_size = extract_viewport_from_browser

      resize_browser(Applitools::Base::Dimension.new((2 * browser_size.width) - cur_viewport_size.width,
        (2 * browser_size.height) - cur_viewport_size.height))
      verify_size(:viewport_size)
    end

    def verify_size(to_verify, sleep_time = VERIFY_SLEEP_PERIOD, retries = VERIFY_RETRIES)
      cur_size = nil

      retries.times do
        sleep(sleep_time)
        cur_size = send(to_verify)

        return if cur_size.values == @dimension.values
      end

      err_msg = "Failed setting #{to_verify} to #{@dimension.values} (current size: #{cur_size.values})"

      Applitools::EyesLogger.error(err_msg)
      raise Applitools::TestFailedError.new(err_msg)
    end

    def browser_size
      @driver.manage.window.size
    end

    def resize_browser(other)
      # Before resizing the window, set its position to the upper left corner (otherwise, there might not be enough
      # "space" below/next to it and the operation won't be successful).
      @driver.manage.window.position = Selenium::WebDriver::Point.new(0, 0)
      @driver.manage.window.size = other
    end

    def to_hash
      Hash[@dimension.each_pair.to_a]
    end
  end
end
