if defined? Watir::Browser
  Watir::Browser.class_eval do
    def driver_for_eyes(eyes)
      is_mobile_device = driver.capabilities['platformName'] ? true : false
      Applitools::Selenium::Driver.new(eyes, driver: driver, is_mobile_device: is_mobile_device)
    end
  end
end
