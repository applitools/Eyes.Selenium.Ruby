if defined? Capybara::Selenium::Driver
  module Applitools::Selenium::Capybara
    class Driver < Capybara::Selenium::Driver
      def driver_for_eyes(eyes)
        browser eyes: eyes
      end

      def browser(options = {})
        eyes = options.delete(:eyes)
        super()
        unless eyes.nil?
          is_mobile_device = @browser.capabilities['platformName'] ? true : false
          @browser = Applitools::Selenium::Driver.new eyes,
            options.merge(driver: @browser,  is_mobile_device: is_mobile_device)
        end
        @browser
      end
    end
  end
end

if defined? Capybara::Session
  Capybara::Session.class_eval do
    def driver_for_eyes(eyes)
      driver.driver_for_eyes eyes
    end
  end
end
