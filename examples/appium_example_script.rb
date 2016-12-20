require 'logger'
require 'appium_lib'

require_relative '../lib/eyes_selenium'

# Based on Appium example: https://github.com/appium/appium/blob/master/sample-code/examples/ruby/

def android_caps
  {
    deviceName: 'Samsung Galaxy S4 Emulator',
    platformName: 'Android',
    platformVersion: 4.4,
    app: ENV['ANDROID_NOTES_LIST_APP'],
    appPackage: 'com.example.android.notepad',
    appActivity: '.NotesList',
    # orientation:         'landscape',
    newCommandTimeout: 300
  }
end

def ios_caps
  {
    deviceName: 'iPhone 6',
    platformName: 'ios',
    platformVersion: 8.4,
    app: ENV['IOS_DEMO_APP'],
    orientation: 'landscape',
    newCommandTimeout: 300
  }
end

def appium_opts
  {
    server_url: 'http://127.0.0.1:4723/wd/hub'
  }
end

eyes = Applitools::Selenium::Eyes.new
eyes.log_handler = Logger.new(STDOUT)
eyes.api_key = ENV['APPLITOOLS_API_KEY']

begin
  # driver = Selenium::WebDriver.for(:remote, :url => 'http://localhost:4723/wd/hub', :desired_capabilities => ios_caps)
  # driver = Appium::Driver.new({caps: android_caps, appium_lib: appium_opts})
  driver = Appium::Driver.new(caps: android_caps, appium_lib: appium_opts)
  driver.start_driver
  # driver.driver.rotate :landscape
  puts "Screen size: #{driver.driver.manage.window.size}"
  puts "orientation: #{driver.driver.orientation}"
  puts driver.caps
  eyes.open(app_name: 'Ruby SDK', test_name: 'Appium Notepad', driver: driver)

  eyes.check_window('No notes')
  eyes.close
ensure
  eyes.abort_if_not_closed
  driver.driver_quit
  # driver.quit
end
