## Before running this, please install ruby(installtion changes depending on machine)
## Then install rake via `gem install rake` (all ruby developers use this gem)
## run `./rake install` in applitools root directory (here), this should install the gem (after we release the gem, users will run `gem install eyes` instead

require 'eyes_selenium'
require 'logger'

Applitools::Eyes.api_key = 'YOUR_API_KEY'
Applitools::Eyes.log_handler = Logger.new(STDOUT)

eyes = Applitools::Eyes.new

my_webdriver = Selenium::WebDriver.for :firefox

begin
  eyes.test(app_name: 'Ruby SDK', test_name: 'Applitools website test', viewport_size: {width: 1024, height: 768}, driver: my_webdriver) do |driver|
    driver.get "http://www.applitools.com"
    eyes.check_window("initial")
    eyes.check_region(:css, 'li.pricing', 'Pricing button')
    driver.find_element(:css, "li.pricing a").click
    eyes.check_window("pricing page")
    el = driver.find_elements(:css, ".footer-row a").first
    driver.action.double_click(el).perform
    eyes.check_window("in forms")
    other_el = driver.find_elements(:css, ".s2member-pro-paypal-registration-email").first
    driver.action.move_to(other_el).click(other_el).send_keys("applitools").perform
    eyes.check_window("end")
  end
ensure
  my_webdriver.quit
end
