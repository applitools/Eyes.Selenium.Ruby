require 'eyes_selenium'
require 'openssl'

OpenSSL::SSL::VERIFY_PEER = OpenSSL::SSL::VERIFY_NONE
##
# Based on Appium example: https://github.com/appium/appium/blob/master/sample-code/examples/ruby/


def android_caps
	{
			deviceName:          'Samsung Galaxy S4 Emulator',
			platformName:        'Android',
			platformVersion:     4.4,
			app:                 '/Users/daniel/test/NotesList.apk',
			appPackage:        	 'com.example.android.notepad',
			appActivity:         '.NotesList',
			# orientation:				 'landscape',
			newCommandTimeout:	 300
	}
end
def ios_caps
	{
			deviceName:          'iPhone 6',
			platformName:        'ios',
			platformVersion:     8.3,
			app:                 '/Users/daniel/Library/Developer/Xcode/DerivedData/HelloXcode-cldusyhxlaclfkbirmthhbgpchqv/Build/Products/Debug-iphonesimulator/HelloXcode.app',
			orientation:	 'landscape',
			newCommandTimeout:	 300
	}
end

def appium_opts
	{
			server_url: 'http://127.0.0.1:4723/wd/hub',
	}
end


@eyes = Applitools::Eyes.new(server_url: 'https://localhost.applitools.com')
@eyes.log_handler = Logger.new(STDOUT)
@eyes.api_key = ENV['APPLITOOLS_API_KEY']
begin
	@driver = Appium::Driver.new({caps: android_caps, appium_lib: appium_opts})
	# @driver = Appium::Driver.new({caps: ios_caps, appium_lib: appium_opts})
	@driver.start_driver
	# @driver.driver.rotate :landscape
  puts "Screen size: #{@driver.driver.manage.window.size}"
  puts "orientation: #{@driver.driver.orientation}"
  puts @driver.caps
	@eyes.open(app_name: 'Selenium Israel', test_name: 'Appium Notepad', driver: @driver)
	@eyes.check_window("No notes")

	@eyes.close
ensure
	@eyes.abort_if_not_closed
	@driver.driver_quit
end
