if defined? Selenium::WebDriver::Driver
  Selenium::WebDriver::Driver.class_eval do
    def driver_for_eyes(eyes)
      is_mobile_device = capabilities['platformName'] ? true : false
      Applitools::Selenium::Driver.new(eyes, driver: self, is_mobile_device: is_mobile_device)
    end
  end
end
