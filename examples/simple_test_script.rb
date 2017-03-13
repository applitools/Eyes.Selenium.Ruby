require_relative '../lib/eyes_selenium'
require 'logger'
require 'openssl'
OpenSSL::SSL::VERIFY_PEER = OpenSSL::SSL::VERIFY_NONE

eyes = Applitools::Selenium::Eyes.new
eyes.api_key = ENV['APPLITOOLS_API_KEY']
eyes.log_handler = Logger.new(STDOUT)

begin
  web_driver = Selenium::WebDriver.for :chrome
  eyes.test(app_name: 'Ruby SDK', test_name: 'Applitools website test', viewport_size: { width: 900, height: 600 },
    driver: web_driver) do |driver|
    driver.get 'http://www.applitools.com'
    eyes.check_window('initial')
    pricing = driver.find_element(:css, '.pricing a')
    eyes.check_region(pricing, 'pricing element')
  end
ensure
  web_driver.quit
end
