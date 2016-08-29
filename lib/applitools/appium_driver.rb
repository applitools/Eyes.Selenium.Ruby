if defined? Appium::Driver
  Appium::Driver.class_eval do
    def driver_for_eyes(eyes)
      Applitools::Selenium::Driver.new(eyes, driver: driver || start_driver, is_mobile_device: true)
    end
  end
end
