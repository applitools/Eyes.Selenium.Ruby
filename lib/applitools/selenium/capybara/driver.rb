require 'applitools/selenium/driver'
module Applitools::Selenium::Capybara
  class Driver < Applitools::Selenium::Driver

    def initialize(eyes, options)
      driver = get_driver(options.delete :driver)
      super eyes, options.merge({driver: driver})

      @is_mobile_device = options.fetch(:is_mobile_device, false)
      @wait_before_screenshots = 0
      @eyes = eyes
      @browser = Applitools::Selenium::Browser.new(self, @eyes)
      driver.instance_variable_set :@browser, self

      Applitools::EyesLogger.warn '"takes_screenshot" capability not found.' unless driver.respond_to? :screenshot_as
    end

    private

    def get_driver driver
      if driver.respond_to? :browser
        return driver.browser
      else
        raise Applitools::EyesAbort.new "Can't find webdriver"
      end

    end

  end
end
