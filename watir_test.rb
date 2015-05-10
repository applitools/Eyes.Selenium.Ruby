require 'eyes_selenium'
require 'logger'
require 'watir-webdriver'


browser = Watir::Browser.new
eyes = Applitools::Eyes.new
eyes.api_key = ENV['APPLITOOLS_API_KEY']
eyes.log_handler = Logger.new(STDOUT)

begin
  eyes.test(app_name: 'Ruby SDK', test_name: 'Applitools website test', viewport_size: {width: 1024, height: 768}, driver: browser) do |driver|
    driver.get 'http://www.applitools.com'
    eyes.check_window('initial')
    eyes.check_region(:css, '.pricing', 'Pricing button')
    driver.find_element(:css, '.pricing a').click
    eyes.check_window('pricing page')
  end
ensure
  browser.quit
end
