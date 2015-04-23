require 'eyes_selenium'
require 'logger'

# require 'openssl'
# OpenSSL::SSL::VERIFY_PEER = OpenSSL::SSL::VERIFY_NONE

eyes = Applitools::Eyes.new

my_webdriver = Selenium::WebDriver.for :chrome
eyes.api_key = ENV['APPLITOOLS_API_KEY']
eyes.log_handler = Logger.new(STDOUT)

begin
  eyes.test(app_name: 'Ruby SDK', test_name: 'Applitools website test', viewport_size: {width: 1024, height: 768}, driver: my_webdriver) do |driver|
    driver.get 'http://www.applitools.com'
    eyes.check_window('initial')
    eyes.check_region(:css, '.pricing', 'Pricing button')
    driver.find_element(:css, '.pricing a').click
    eyes.check_window('pricing page')
  end
ensure
  my_webdriver.quit
end
