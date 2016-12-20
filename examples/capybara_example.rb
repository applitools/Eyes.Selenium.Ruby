require 'rspec'
require 'capybara/rspec'
require_relative '../lib/eyes_selenium'
require 'applitools/capybara'

##
# This will register capybara driver :eyes by performing
#
#   Capybara.register_driver :eyes do |app|
#     Capybara::Selenium::Driver.new(options)
#   end
#
# (options are passed to Applitools.register_capybara_driver method) and set it as a default driver.
# The page.driver.browser method will return Applitools::Selenium::Driver instance,
# based on standard Selenium::Webdriver driver, when eyes have opened.
# The page.driver.browser method will contain Selenium::Webdriver
# instance (without applitools wrapper), after eyes have closed
#
Applitools.register_capybara_driver :browser => :chrome

# Register another driver if needed
Capybara.register_driver :selenium_chrome do |app|
  Capybara::Selenium::Driver.new(app, :browser => :chrome)
end

# And even one more
Capybara.register_driver :selenium_firefox do |app|
  Capybara::Selenium::Driver.new(app, :browser => :firefox)
end

describe 'Capybara Example', :type => :feature, :js => true do
  let(:eyes) do
    Applitools::Selenium::Eyes.new.tap do |eyes|
      eyes.api_key = ENV['APPLITOOLS_API_KEY']
      eyes.log_handler = Logger.new(STDOUT)
    end
  end

  it 'Simple test' do
    eyes.open(app_name: 'Ruby SDK', test_name: 'Capybara test', driver: page,
               viewport_size: { width: 800, height: 600 })
    visit 'http://github.com'
    eyes.check_window('homepage')
    fill_in('user[login]', with: 'user')
    eyes.check_window('homepage with username')
    eyes.close
  end

  ##
  # This will use :eyes driver with standard browser, without Applitools wrapper
  # In our case  - Selenium::Webdriver for :crome
  #
  it 'common capybara test' do
    visit 'http://github.com'
    fill_in('user[login]', with: 'user')
    # and so on
  end

  it 'other chrome test' do
    ##
    # this uses :selenium_chrome driver (see Capybara.register_driver block) instead of :eyes driver
    Capybara.using_driver :selenium_chrome do
      visit 'http://github.com'
      fill_in('user[login]', with: 'user')
      # and so on
    end
  end

  after :each do
    eyes.abort_if_not_closed
  end
end

describe 'Other Capybara tests', :type => :feature, :js => true do
  it 'some other chrome test' do
    Capybara.using_driver :selenium_chrome do
      visit 'http://github.com'
      fill_in('user[login]', with: 'user')
      # and so on
    end
  end
end
