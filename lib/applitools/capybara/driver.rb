module Applitools::Capybara
  class Driver < Capybara::Selenium::Driver
    def browser(options = {})
      eyes = options.delete(:eyes)
      super()
      @browser = Applitools::Selenium::Driver.new eyes, options.merge(driver: @browser) if eyes.present?
      @browser
    end
  end
end
