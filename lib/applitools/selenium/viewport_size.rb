module Applitools::Selenium
  class ViewportSize
    JS_GET_VIEWPORT_SIZE = (<<-JS).freeze
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
      @dimension = setup_dimension(dimension)
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
      resize_browser new_size(browser_size: browser_size, current_viewport: extract_viewport_from_browser, new_viewport: @dimension)
      verify_size(:viewport_size)
    end

    def verify_size(to_verify)
      current_size = nil

      VERIFY_RETRIES.times do
        sleep(VERIFY_SLEEP_PERIOD)
        current_size = send(to_verify)

        return if current_size.values == @dimension.values
      end

      err_msg = "Failed setting #{to_verify} to #{@dimension.values} (current size: #{current_size.values})"

      Applitools::EyesLogger.error(err_msg)
      raise Applitools::TestFailedError.new(err_msg)
    end

    def browser_size
      @driver.manage.window.size
    end

    def resize_browser(other)
      # Before resizing the window, set its position to the upper left corner (otherwise, there might not be enough
      # "space" below/next to it and the operation won't be successful).
      browser_to_upper_left_corner
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
      return dimension if dimension.respond_to?(:width) & dimension.respond_to?(:height)
      return Applitools::Base::Dimension.new(dimension[:width], dimension[:height]) if dimension.is_a?(Hash) && (dimension.keys & [:width, :height]).size == 2
      raise ArgumentError, "expected #{@dimension.inspect}:#{@dimension.class} to respond to #width and #height, or be  a hash with these keys."
    end

    def new_size(options)
      raise ArgumentError, "expected #{options.inspect}:#{options.class} to be a hash with keys :browser_size, :current_viewport, :new_viewport" unless options.is_a?(Hash) && (options.keys & [:browser_size, :current_viewport, :new_viewport]).size == 3
      new_width = options[:browser_size].width - options[:current_viewport].width + options[:new_viewport].width
      new_height = options[:browser_size].height - options[:current_viewport].height + options[:new_viewport].height
      Applitools::Base::Dimension.new(new_width, new_height)
    end
  end
end
