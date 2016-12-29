module Applitools::Selenium::Capybara
  module CapybaraSettings
    # Registers Capybara driver which will be used by eyes and sets it as default Capybara driver.
    # The name of the driver is :eyes, and the driver is a descendant of class Capybara::Selenium::Driver.
    # Options are eventually passed to drivers constructor
    # @param [Hash] options
    # @example
    #   Applitools.register_capybara_driver :browser => :chrome
    # @example
    #   Applitools.register_capybara_driver :browser => :remote, :url => 'remote_url', :desired_capabilities => {}
    def register_capybara_driver(options = {})
      Capybara.register_driver :eyes do |app|
        Applitools::Selenium::Capybara::Driver.new app, options
      end
      Capybara.default_driver = :eyes
      Capybara.javascript_driver = :eyes
    end
  end
end
