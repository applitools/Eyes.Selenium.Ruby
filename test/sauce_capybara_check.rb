require 'capybara'
require 'sauce'
require 'sauce/capybara'
require_relative '../lib/eyes_selenium'
require 'openssl'
OpenSSL::SSL::VERIFY_PEER = OpenSSL::SSL::VERIFY_NONE

Sauce.config do |config|
  config[:browsers] = [
      ["OS X 10.10", "chrome", "39.0"]
  ]
  config[:start_tunnel] = false
  # config[:sauce_connect_4_executable] = '/path/to/sauce-connect/bin/sc'
end

Capybara.javascript_driver = :sauce

describe 'A Saucy Example Group', :sauce => true do
  before :each do
    @eyes = Applitools::Eyes.new
    @eyes.api_key = ENV['APPLITOOLS_API_KEY']
    @eyes.log_handler = Logger.new(STDOUT)
  end

  it 'Simple test' do
    driver = @eyes.open(app_name: 'Ruby SDK', test_name: 'Capybara test', driver: selenium.driver, viewport_size: {width: 800, height: 600})
    driver.navigate.to 'http://github.com'
    @eyes.check_window('homepage')
    username = driver.find_element(:name, 'user[login]')
    username.send_keys('user')
    @eyes.check_window('homepage with username')
    @eyes.close(false)
  end

  after :each do
    @eyes.abort_if_not_closed
  end
end