require 'rspec'
require 'capybara/rspec'
require_relative '../lib/eyes_selenium'
require 'openssl'
OpenSSL::SSL::VERIFY_PEER = OpenSSL::SSL::VERIFY_NONE

Capybara.register_driver :selenium do |app|
  Capybara::Selenium::Driver.new(app, :browser => :chrome)
end

Capybara.javascript_driver = :selenium

# require 'capybara/poltergeist'
#
# Capybara.register_driver :poltergeist_app do |app|
#   Capybara::Poltergeist::Driver.new(app, :js_errors => false)
# end
#
# Capybara.javascript_driver = :poltergeist_app

describe 'Capybara Example', :type => :feature, :js => true do
  let(:eyes) do
    Applitools::Eyes.new.tap do |eyes|
      eyes.api_key = ENV['APPLITOOLS_API_KEY']
      eyes.log_handler = Logger.new(STDOUT)
    end
  end

  it 'Simple test' do
    eyes.open(app_name: 'Ruby SDK', test_name: 'Capybara test', driver: page.driver,
               viewport_size: { width: 800, height: 600 })
    visit 'http://github.com'
    eyes.check_window('homepage')
    fill_in('user[login]', with: 'user')
    eyes.check_window('homepage with username')
    eyes.close
  end

  after :each do
    eyes.abort_if_not_closed
  end
end
