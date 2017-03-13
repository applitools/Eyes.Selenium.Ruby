# This module is used for compatibility with Applitools API.
# Should be extended by Poltergeist driver instance.
module Applitools::Poltergeist
  module ApplitoolsCompatible
    # Implementation of `screenshot_as` method for PhantomJS.
    # Realisation uses Poltergeist binding to `renderBase64` PhantomJS method.
    def screenshot_as(fmt)
      Base64.decode64(browser.render_base64(fmt))
    end

    # Poltergeist driver does not have `manage` and `window` methods.
    # In Applitools these methods are used in a chain to get size by `size` method call.
    %w(manage window).each do |method_name|
      define_method(method_name) { self }
    end

    # Method provides opened window size in Applitools format.
    def size
      size = window_size(current_window_handle)
      Applitools::Base::Dimension.new(size[0], size[1])
    end

    # Method changes opened window size in a way how original Applitools::Selenium::Driver does.
    def size=(new_size)
      resize(new_size.width, new_size.height)
    end

    # def switch_to(*args)
    #   switch_to_frame(*args)
    # end
  end
end
