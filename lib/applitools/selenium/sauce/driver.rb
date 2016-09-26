if defined? Sauce::Selenium2
  if defined? Capybara
    Sauce::Capybara::Driver.class_eval do
      def driver_for_eyes(eyes)
        browser.raw_driver eyes: eyes
      end

      def use_native_browser
        browser.use_native_browser
      end
    end
  end

  Sauce::Selenium2.class_eval do
    def driver_for_eyes(eyes)
      raw_driver eyes: eyes
    end

    def raw_driver(options = {})
      eyes = options.delete(:eyes)
      @native_driver ||= @raw_driver
      unless eyes.nil?
        is_mobile_device = @raw_driver.capabilities['platformName'] ? true : false
        @raw_driver = Applitools::Selenium::Driver.new eyes,
          options.merge(driver: @raw_driver, is_mobile_device: is_mobile_device)
      end
      @raw_driver
    end

    def use_native_browser
      @raw_driver = @native_driver
    end
  end
end
