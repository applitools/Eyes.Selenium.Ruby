module Applitools::Utils
  module EyesSeleniumUtils
    extend self

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

    JS_GET_USER_AGENT = <<-JS.freeze
      return navigator.userAgent;
    JS

    JS_GET_DEVICE_PIXEL_RATIO = <<-JS.freeze
      return window.devicePixelRatio;
    JS

    JS_GET_PAGE_METRICS = <<-JS.freeze
      return {
        scrollWidth: document.documentElement.scrollWidth,
        bodyScrollWidth: document.body.scrollWidth,
        clientHeight: document.documentElement.clientHeight,
        bodyClientHeight: document.body.clientHeight,
        scrollHeight: document.documentElement.scrollHeight,
        bodyScrollHeight: document.body.scrollHeight
      };
    JS

    JS_GET_CURRENT_SCROLL_POSITION = <<-JS.freeze
      return (function() {
        var doc = document.documentElement;
        var x = (window.scrollX || window.pageXOffset || doc.scrollLeft) - (doc.clientLeft || 0);
        var y = (window.scrollY || window.pageYOffset || doc.scrollTop)  - (doc.clientTop || 0);

        return {left: parseInt(x, 10) || 0, top: parseInt(y, 10) || 0};
      }());
    JS

    JS_SCROLL_TO = <<-JS.freeze
      window.scrollTo(%{left}, %{top});
    JS

    JS_GET_CURRENT_TRANSFORM = <<-JS.freeze
      return document.body.style.transform;
    JS

    JS_SET_TRANSFORM = <<-JS.freeze
      return (function() {
        var originalTransform = document.body.style.transform;
        document.body.style.transform = '%{transform}';
        return originalTransform;
      }());
    JS

    JS_SET_OVERFLOW = <<-JS.freeze
      return (function() {
        var origOF = document.documentElement.style.overflow;
        document.documentElement.style.overflow = '%{overflow}';
        return origOF;
      }());
    JS

    OVERFLOW_HIDDEN = 'hidden'.freeze
    BROWSER_SIZE_CALCULATION_RETRIES = 3
    VERIFY_RETRIES = 3
    VERIFY_SLEEP_PERIOD = 1


    def current_scroll_position(executor)
        position = Applitools::Utils.symbolize_keys executor.execute_script(JS_GET_CURRENT_SCROLL_POSITION).to_hash
        Applitools::Core::Location.new position[:left], position[:top]
    end

    def scroll_to(executor, point)
      with_timeout(0.25) {executor.execute_script(JS_SCROLL_TO % { left: point.left, top: point.top })}
    end

    def extract_viewport_size(executor)
      Applitools::EyesLogger.debug 'extract_viewport_size()'
      width = nil
      height = nil

      begin
        width, height = executor.execute_script(JS_GET_VIEWPORT_SIZE)
        result = Applitools::Core::RectangleSize.from_any_argument width: width, height: height
        Applitools::EyesLogger.debug "Viewport size is #{result}."
        return result
      rescue => e
        Applitools::EyesLogger.error "Failed extracting viewport size using JavaScript: (#{e.message})"
      end

      Applitools::EyesLogger.info 'Using window size as viewport size.'

      width, height = executor.manage.window.size.to_a
      width, height = height, width if executor.landscape_orientation? && height > width

      result = Applitools::Core::RectangleSize.new width, height
      Applitools::EyesLogger.debug "Viewport size is #{result}."
      result
    end

    def entire_page_size(executor)
      metrics = page_metrics(executor)
      max_document_element_height = [metrics[:client_height], metrics[:scroll_height]].max
      max_body_height = [metrics[:body_client_height], metrics[:body_scroll_height]].max

      total_width = [metrics[:scroll_width], metrics[:body_scroll_width]].max
      total_height = [max_document_element_height, max_body_height].max

      Applitools::Core::RectangleSize.new(total_width, total_height)
    end

    def device_pixel_ratio(executor)
      executor.execute_script(JS_GET_DEVICE_PIXEL_RATIO)
    end

    def page_metrics(executor)
      Applitools::Utils.underscore_hash_keys(executor.execute_script(JS_GET_PAGE_METRICS))
    end

    def hide_scrollbars(executor)
      set_overflow executor, OVERFLOW_HIDDEN
    end

    def set_overflow(executor, overflow)
      with_timeout(0.1) { executor.execute_script(JS_SET_OVERFLOW % { overflow:  overflow}) }
    end

    def set_viewport_size(executor, viewport_size)
      Applitools::Core::ArgumentGuard.not_nil 'viewport_size', viewport_size
      Applitools::EyesLogger.info "Set viewport size #{viewport_size}"

      # Before resizing the window, set its position to the upper left corner (otherwise, there might not be enough
      # "space" below/next to it and the operation won't be successful).
      begin
        executor.manage.window.position = Selenium::WebDriver::Point.new(0, 0)
      rescue Selenium::WebDriver::Error::UnsupportedOperationError => e
        Applitools::EyesLogger.error e.message << '\n Continue...'
      end

      actual_viewport_size = extract_viewport_size(executor)

      Applitools::EyesLogger.info "Initial viewport size: #{actual_viewport_size}"

      if actual_viewport_size == viewport_size
        Applitools::EyesLogger.info 'Required size is already set.'
        return
      end

      browser_size_calculation_count = 0
      while browser_size_calculation_count < BROWSER_SIZE_CALCULATION_RETRIES
        raise Applitools::TestFailedError.new 'Failed to set browser size!' \
          " (current size: #{Applitools::Core::RectangleSize.for(executor.manage.window.size)})" unless
            resize_attempt(executor, viewport_size)
        browser_size_calculation_count += 1
        if viewport_size == extract_viewport_size(executor)
          Applitools::EyesLogger.info "Actual viewport size #{viewport_size}."
          return
        end
      end
      raise Applitools::TestFailedError.new 'Failed to set viewport size'
    end



    private

    def resize_attempt(driver, required_viewport_size)
      actual_viewport_size = extract_viewport_size(driver)
      Applitools::EyesLogger.info "Actual viewport size #{actual_viewport_size}."
      required_browser_size = Applitools::Core::RectangleSize.for(driver.manage.window.size) - actual_viewport_size +
          required_viewport_size

      retries_left = VERIFY_RETRIES

      until retries_left.zero?
        return true if Applitools::Core::RectangleSize.for(driver.manage.window.size) == required_browser_size
        Applitools::EyesLogger.info "Trying to set browser size to #{required_browser_size}."
        driver.manage.window.size = required_browser_size
        sleep VERIFY_SLEEP_PERIOD
        Applitools::EyesLogger.info "Required browser size #{required_browser_size}, " \
          "Current browser size #{Applitools::Core::RectangleSize.for(driver.manage.window.size)}"
        retries_left -= 1
      end
      false
    end

    def with_timeout(timeout, &block)
      raise 'You have to pass block to method with_timeout' unless block_given?
      yield.tap {sleep timeout}
    end
  end
end