module Applitools::Selenium
  class Browser
    JS_GET_USER_AGENT = (<<-JS).freeze
      return navigator.userAgent;
    JS

    JS_GET_DEVICE_PIXEL_RATIO = (<<-JS).freeze
      return window.devicePixelRatio;
    JS

    JS_GET_PAGE_METRICS = (<<-JS).freeze
      return {
        scrollWidth: document.documentElement.scrollWidth,
        bodyScrollWidth: document.body.scrollWidth,
        clientHeight: document.documentElement.clientHeight,
        bodyClientHeight: document.body.clientHeight,
        scrollHeight: document.documentElement.scrollHeight,
        bodyScrollHeight: document.body.scrollHeight
      };
    JS

    JS_GET_CURRENT_SCROLL_POSITION = (<<-JS).freeze
      return (function() {
        var doc = document.documentElement;
        var x = (window.scrollX || window.pageXOffset || doc.scrollLeft) - (doc.clientLeft || 0);
        var y = (window.scrollY || window.pageYOffset || doc.scrollTop)  - (doc.clientTop || 0);

        return {left: parseInt(x, 10) || 0, top: parseInt(y, 10) || 0};
      }());
    JS

    JS_SCROLL_TO = (<<-JS).freeze
      window.scrollTo(%{left}, %{top});
    JS

    JS_GET_CURRENT_TRANSFORM = (<<-JS).freeze
      return document.body.style.transform;
    JS

    JS_SET_TRANSFORM = (<<-JS).freeze
      return (function() {
        var originalTransform = document.body.style.transform;
        document.body.style.transform = '%{transform}';
        return originalTransform;
      }());
    JS

    JS_SET_OVERFLOW = (<<-JS).freeze
      return (function() {
        var origOF = document.documentElement.style.overflow;
        document.documentElement.style.overflow = '%{overflow}';
        return origOF;
      }());
    JS

    EPSILON_WIDTH = 12.freeze

    def initialize(driver, eyes)
      @driver = driver
      @eyes = eyes
    end

    def chrome?
      @driver.browser == :chrome
    end

    def user_agent
      @user_agent ||= @driver.execute_script(JS_GET_USER_AGENT)
    end

    def image_normalization_factor(image)
      if image.width == @eyes.viewport_size.extract_viewport_from_browser.width ||
          (image.width - entire_page_size.width).abs <= EPSILON_WIDTH
        return 1
      end

      1.to_f / device_pixel_ratio
    end

    def entire_page_size
      @entire_page_size ||= begin
        max_document_element_height = [page_metrics[:client_height], page_metrics[:scroll_height]].max
        max_body_height = [page_metrics[:body_client_height], page_metrics[:body_scroll_height]].max

        total_width =  [page_metrics[:scroll_width], page_metrics[:body_scroll_width]].max
        total_height = [max_document_element_height, max_body_height].max

        Applitools::Base::Dimension.new(total_width, total_height)
      end
    end

    def current_scroll_position
      position = @driver.execute_script(JS_GET_CURRENT_SCROLL_POSITION)
      Point.new(position[:x], position[:y])
    end

    def scroll_to(point)
      @driver.execute_script(JS_SCROLL_TO % { left: point.left, top: point.top })
    end

    def current_transform
      @driver.execute_script(JS_GET_CURRENT_TRANSFORM)
    end

    def translate_to(point)
      @driver.execute_script(JS_SET_TRANSFORM % { transform: "translate(-#{point.left}px, -#{point.top}px)" })
    end

    def set_overflow(overflow)
      driver.execute_script(JS_SET_OVERFLOW % { overflow: overflow })
    end

    private

    def device_pixel_ratio
      @device_pixel_ratio ||= @driver.execute_script(JS_GET_DEVICE_PIXEL_RATIO)
    end

    def page_metrics
      @page_metrics ||= Applitools::Utils.underscore_hash_keys(@driver.execute_script(JS_GET_PAGE_METRICS))
    end
  end
end
