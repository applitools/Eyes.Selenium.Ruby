module Applitools::Utils
  module EyesSeleniumUtils
    extend self
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

    def current_scroll_position(executor)
        position = Applitools::Utils.symbolize_keys executor.execute_script(JS_GET_CURRENT_SCROLL_POSITION).to_hash
        Applitools::Core::Location.new position[:left], position[:top]
    end

    def scroll_to(executor, point)
      executor.execute_script(JS_SCROLL_TO % { left: point.left, top: point.top }, 0.25)
    end

    def entire_page_size(executor)
      metrics = page_metrics(executor)
      max_document_element_height = [metrics[:client_height], metrics[:scroll_height]].max
      max_body_height = [metrics[:body_client_height], metrics[:body_scroll_height]].max

      total_width = [metrics[:scroll_width], metrics[:body_scroll_width]].max
      total_height = [max_document_element_height, max_body_height].max

      Applitools::Core::RectangleSize.new(total_width, total_height)
    end

    def page_metrics(executor)
      Applitools::Utils.underscore_hash_keys(executor.execute_script(JS_GET_PAGE_METRICS))
    end
  end
end