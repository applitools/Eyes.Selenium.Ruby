require 'httparty'
class Applitools::Selenium::ScreenshotTaker
  include HTTParty
  headers 'Accept' => 'application/json'
  headers 'Content-Type' => 'application/json'

  attr_reader :driver_server_uri, :driver_session_id

  def initialize(driver_server_uri, driver_session_id)
    @driver_server_uri = driver_server_uri
    @driver_session_id = driver_session_id
  end

  def screenshot
    res = self.class.get(driver_server_uri.to_s.gsub(/\/$/,"") + "/session/#{driver_session_id}/screenshot")
    res.parsed_response['value']
  end
end
