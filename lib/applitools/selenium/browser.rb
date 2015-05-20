module Applitools::Selenium
  class Browser
    JS_GET_USER_AGENT = 'return navigator.userAgent;'.freeze
    JS_GET_DEVICE_PIXEL_RATIO = 'return window.devicePixelRatio;'.freeze
    JS_GET_PAGE_METRICS = (<<-EOF).freeze
      return {
        scrollWidth: document.documentElement.scrollWidth,
        bodyScrollWidth: document.body.scrollWidth,
        clientHeight: document.documentElement.clientHeight,
        bodyClientHeight: document.body.clientHeight,
        scrollHeight: document.documentElement.scrollHeight,
        bodyScrollHeight: document.body.scrollHeight
      };
    EOF

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

    private

    def device_pixel_ratio
      @device_pixel_ratio ||= @driver.execute_script(JS_GET_DEVICE_PIXEL_RATIO)
    end

    def page_metrics
      @page_metrics ||= Applitools::Utils.underscore_hash_keys(@driver.execute_script(JS_GET_PAGE_METRICS))
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
  end
end
