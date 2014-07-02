require 'eyes_selenium'

Applitools::Eyes.api_key = 'YOUR_API_KEY'

## 
# Based on Appium example: https://github.com/appium/appium/blob/master/sample-code/examples/ruby/

desired_capabilities = {
    "device" => "Android",
    "version" => "4.2",
    "app" => "http://appium.s3.amazonaws.com/NotesList.apk",
    "app-package" => "com.example.android.notepad",
    "app-activity" => ".NotesList"
}

def create_note(text)
	@driver.find_element(:name, "New note").click
	@driver.find_element(:tag_name, "textfield").send_keys text
	@eyes.check_window("Note: #{text}")
	@driver.find_element(:name, "Save").click
end

def clear_note_by_text(text)
	@driver.find_element(:name, "#{text}").click
	@driver.find_element(:tag_name, "textfield").clear
	@driver.find_element(:name, "Save").click
end

@eyes = Applitools::Eyes.new
begin
	@driver = Selenium::WebDriver.for(:remote, :url => 'http://127.0.0.1:4723/wd/hub', :desired_capabilities => desired_capabilities)
	@driver = @eyes.open(app_name: 'Selenium Israel', test_name: 'Appium Notepad', driver: @driver)
	@eyes.check_window("No notes")

	create_note "I didn't expect a kind of Spanish Inquisition!"
	create_note "Nobody expects the Spanish Inquisition!"
	@eyes.check_window("Two notes")

	clear_note_by_text "I didn't expect a kind of Spanish Inquisition!"
	@eyes.check_window("One note")

	@eyes.close
ensure
	sleep 5
	@eyes.abort_if_not_closed
	@driver.quit
end
