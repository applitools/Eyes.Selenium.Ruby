require 'rspec'
require_relative './sauce_driver'
require_relative '../lib/eyes_selenium'

describe 'A Saucy Example Group', sauce: true do
  let!(:eyes) do
    Applitools::Selenium::Eyes.new.tap do |eyes|
      eyes.api_key = ENV['APPLITOOLS_API_KEY']
      eyes.log_handler = Logger.new(STDOUT)
    end
  end

  it 'Simple test' do
    eyes.test(app_name: 'Ruby SDK', test_name: 'Sauce plain test', driver: SauceDriver.new_driver,
              viewport_size: { width: 800, height: 600 }) do |driver|
      driver.get 'http://github.com'
      eyes.check_window('homepage')
      driver.find_element(:css, 'input[name="user[login]"]').send_keys 'user'
      eyes.check_window('homepage with username')
    end
  end

  after :each do
    eyes.abort_if_not_closed
  end
end
