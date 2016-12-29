if defined? Capybara::Selenium::Driver
  module Applitools::Selenium::Capybara
    # @!visibility private
    class Driver < Capybara::Selenium::Driver
      def driver_for_eyes(eyes)
        browser eyes: eyes
      end

      def browser(options = {})
        eyes = options.delete(:eyes)
        @native_browser ||= super()
        unless eyes.nil?
          is_mobile_device = @browser.capabilities['platformName'] ? true : false
          @browser = Applitools::Selenium::Driver.new eyes,
            options.merge(driver: @browser,  is_mobile_device: is_mobile_device)
        end
        @browser
      end

      def use_native_browser
        @browser = @native_browser
      end
    end
  end
end

if defined? Capybara::Session
  Capybara::Session.class_eval do
    def driver_for_eyes(eyes)
      driver.driver_for_eyes eyes
    end

    def use_native_browser
      driver.use_native_browser if driver.respond_to? :use_native_browser
    end
  end
end
