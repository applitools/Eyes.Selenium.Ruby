module Applitools::Poltergeist
  module ApplitoolsCompatible
    def screenshot_as(fmt)
      Base64.decode64(browser.render_base64(fmt))
    end

    def manage
      self
    end

    def window
      self
    end

    def size
      size = window_size(current_window_handle)
      Applitools::Base::Dimension.new(size[0], size[1])
    end
  end
end
