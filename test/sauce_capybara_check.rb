require 'rspec'
require 'sauce'
require 'sauce/capybara'

require_relative '../lib/eyes_selenium'
require 'openssl'

OpenSSL::SSL::VERIFY_PEER = OpenSSL::SSL::VERIFY_NONE

Sauce.config do |config|
  config[:browsers] = [
    ['OS X 10.10', 'chrome', '39.0']
  ]
  config[:start_tunnel] = false
  # config[:sauce_connect_4_executable] = '/path/to/sauce-connect/bin/sc'
end

Capybara.configure do |c|
  c.javascript_driver = :sauce
  c.default_driver = :sauce
end

describe 'A Saucy Example Group', sauce: true do
  let!(:eyes) do
    Applitools::Eyes.new.tap do |eyes|
      eyes.api_key = ENV['APPLITOOLS_API_KEY']
      eyes.log_handler = Logger.new(STDOUT)
    end
  end

  it 'Simple test' do
    eyes.open(app_name: 'Ruby SDK', test_name: 'Capybara test', driver: page,
      viewport_size: { width: 800, height: 600 })
    visit 'http://github.com'
    eyes.check_window('homepage')
    fill_in 'user[login]', with: 'user'
    eyes.check_window('homepage with username')
    eyes.close(false)
  end

  after :each do
    @eyes.abort_if_not_closed
  end
end
