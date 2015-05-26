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
    MIN_SCREENSHOT_PART_HEIGHT = 10.0.freeze
    MAX_SCROLLBAR_SIZE = 50.0.freeze

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
      Applitools::Base::Point.new(position[:x], position[:y])
    end

    def scroll_to(point)
      @driver.execute_script(JS_SCROLL_TO % { left: point.left, top: point.top })
    end

    def current_transform
      @driver.execute_script(JS_GET_CURRENT_TRANSFORM)
    end

    def set_transform(transform)
       @driver.execute_script(JS_SET_TRANSFORM % { transform: transform })
    end

    def translate_to(point)
      set_transform("translate(-#{point.left}px, -#{point.top}px)")
    end

    def set_overflow(overflow)
      driver.execute_script(JS_SET_OVERFLOW % { overflow: overflow })
    end

    def screenshot
      # Scroll to the top/left corner of the screen.
      original_scroll_position = current_scroll_position
      scrollTo(Applitools::Base::Point::TOP_LEFT)
      if current_scroll_position != Applitools::Base::Point::TOP_LEFT
        raise 'Could not scroll to the top/left corner of the screen!'
      end

      # Translate to top/left of the page (notice this is different from JavaScript scrolling).
      if @eyes.use_css_transition
        original_transform = current_transform
        translate_to(Applitools::Base::Point::TOP_LEFT)
      end

      # Hide scrollbars.
      if @eyes.hide_scrollbars
        original_overflow = set_overflow('hidden')
      end

      # Take screenshot of the (0,0) tile.
      screenshot = take_screenshot

      # Normalize screenshot width/height.
      size_factor = 1
      page_size = entire_page_size
      factor = image_normalization_factor(screenshot)
      if factor == 0.5
        size_factor = 0.5
        page_size.width *= size_factor
        page_size.height *= size_factor
        page_size.width = [page_size.width, screenshot.width].max
      end

      # NOTE: this is required! Since when calculating the screenshot parts for full size, we use a screenshot size
      # which is a bit smaller (see comment below).
      if screenshot.width < entire_page_size.width || screenshot.height < entire_page_size.height)
        # We use a smaller size than the actual screenshot size in order to eliminate duplication of bottom scroll bars,
        # as well as footer-like elements with fixed position.
        max_scrollbar_size = @eyes.use_css_transition ? 0 : MAX_SCROLLBAR_SIZE
        height = [screenshot.height - (max_scrollbar_size * size_factor), MIN_SCREENSHOT_PART_HEIGHT * size_factor]
        screenshot_part_size = Applitools::Base::Dimension.new(image.width, height)

        parts = Applitools::Base::Region.new(0, 0, entire_page_size.width, entire_page_size.height).
          subregions(screenshot_part_size).map do |screenshot_part|
            process_screenshot_part(screenshot_part, screenshot, size_factor)
        end

        screenshot = Applitools::Utils::ImageUtils.stitch_images(entire_page_size, parts)
      end

      if @eyes.hide_scrollbars
        set_overflow(original_overflow)
      end

      if @eyes.use_css_transition
        set_transform(original_transform)
      end

      scroll_to(original_scroll_position)

      screenshot
    end

    private

    def device_pixel_ratio
      @device_pixel_ratio ||= @driver.execute_script(JS_GET_DEVICE_PIXEL_RATIO)
    end

    def page_metrics
      @page_metrics ||= Applitools::Utils.underscore_hash_keys(@driver.execute_script(JS_GET_PAGE_METRICS))
    end

    def process_screenshot_part(part, screenshot, size_factor)
      # Skip (0,0), as we already got the screenshot.
      if part.left == 0 && part.top == 0
        return Applitools::Base::ImagePosition.new(screenshot, Applitools::Base::Point::TOP_LEFT .new(0, 0))
      end

      part_coors = Applitools::Base::Point.new(part.left, part.top)
      part_coords_normalized = Applitools::Base::Point.new(part.left.to_f / size_factor, part.top.to_f / size_factor)

      if @eyes.use_css_transition
        current_position = translate_to(part_coords_normalized)
      else
        position = scroll_to(part_coords_normalized)
        current_position = Applitools::Base::Point.new(position.left.to_f * size_factor, position.top * size_factor)
      end

      Applitools::Base::ImagePosition.new(@driver.take_screenshot, current_position)
    end
  end
end
