require 'sauce/capybara'
module Applitools::Sauce

end

# Sauce::Capybara::Driver.class_eval do
#   alias sauce_browser browser
#   def browser(options={})
#     eyes = options.delete(:eyes)
#     sauce_browser
#     @browser = Applitools::Selenium::Driver.new eyes, options.merge(driver: @browser) if eyes.present?
#     @browser
#   end
# end

Sauce::Selenium2.class_eval do
  def raw_driver(options={})
    eyes = options.delete(:eyes)
    @raw_driver = Applitools::Selenium::Driver.new eyes, options.merge(driver: @raw_driver) if eyes.present?
    @raw_driver
  end
end