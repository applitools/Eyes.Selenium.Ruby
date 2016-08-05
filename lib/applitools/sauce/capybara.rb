require 'sauce/capybara'

Sauce::Selenium2.class_eval do
  def raw_driver(options = {})
    eyes = options.delete(:eyes)
    @raw_driver = Applitools::Selenium::Driver.new eyes, options.merge(driver: @raw_driver) if eyes.present?
    @raw_driver
  end
end
