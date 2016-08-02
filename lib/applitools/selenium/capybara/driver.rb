require 'applitools/selenium/driver'
module Applitools::Selenium::Capybara
  class Driver < Applitools::Selenium::Driver
    def initialize(eyes, options)
      capybara_driver = options.delete :driver
      driver = get_driver capybara_driver
      super eyes, options.merge(driver: driver)
      capybara_driver.instance_variable_set :@browser, self
    end

    private

    def get_driver(driver)
      return driver.browser if driver.respond_to? :browser
      raise Applitools::EyesAbort.new 'Can\'t find webdriver'
    end
  end
end
