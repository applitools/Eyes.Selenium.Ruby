require 'httparty'

class Applitools::Selenium::AgentConnector

  include HTTParty
  headers 'Accept' => 'application/json'
  ssl_ca_file File.join(File.dirname(File.expand_path(__FILE__)), '../../../certs/cacert.pem').to_s
  default_timeout 300

  # comment out when not debugging
  #http_proxy 'localhost', 8888
  #debug_output $stdout

  attr_accessor :server_url, :api_key

  def server_url=(server_url)
    @server_url = server_url
    # Remove trailing slashes in server url and add the running sessions endpoint uri.
    @endpoint_uri = server_url.gsub(/\/$/,'') + '/api/sessions/running'
  end

  def initialize(server_url)
    self.server_url = server_url
  end

  def match_window(session, data)
    self.class.headers 'Content-Type' => 'application/octet-stream'
    json_data = data.to_hash.to_json.force_encoding('BINARY') # Notice that this does not include the screenshot
    body = [json_data.length].pack('L>') + json_data + data.screenshot
    Applitools::EyesLogger.debug 'Sending match data...'
    res = self.class.post(@endpoint_uri + "/#{session.id}", query: {apiKey: api_key}, body: body)
    raise Applitools::EyesError.new('could not connect to server') if res.code != 200
    Applitools::EyesLogger.debug "Got response! #{res.parsed_response['asExpected']}"
    res.parsed_response['asExpected']
  end

  def start_session(session_start_info)
   self.class.headers 'Content-Type' => 'application/json'
   res = self.class.post(@endpoint_uri, query: {apiKey: api_key}, body: { startInfo: session_start_info.to_hash }.to_json)
   status_code = res.response.message
   parsed_res = res.parsed_response
   Applitools::Selenium::Session.new(parsed_res['id'], parsed_res['url'], status_code == 'Created' )
  end

  def stop_session(session, aborted=nil, save=false)
    self.class.headers 'Content-Type' => 'application/json'
    res = self.class.send_long_request('stop_session') do
        self.class.delete(@endpoint_uri + "/#{session.id}", query: { aborted: aborted.to_s, updateBaseline: save.to_s, apiKey: api_key })
    end
    parsed_res = res.parsed_response
    parsed_res.delete('$id')
    Applitools::Selenium::TestResults.new(*parsed_res.values)
  end

  private
  ##
  # Static method for sending long running requests
  # Args:
  #   name: (String) name of the method being executed
  #   request_block: (block) The actual block to be executed. Will be called using "yield"
  # noinspection RubyUnusedLocalVariable
  def self.send_long_request(name, &request_block)
    delay = 2  # seconds

    headers 'Eyes-Expect' => '202-accepted'
    while true
      # Date should be in RFC 1123 format
      headers 'Eyes-Date' => Time.now.utc.strftime('%a, %d %b %Y %H:%M:%S GMT')
      res = yield
      if res.code != 202
        return res
      end
      Applitools::EyesLogger.debug "#{name}: Still running... Retrying in #{delay}s"
      sleep delay
      delay = [10, (delay*1.5).round].min
    end
  end
end
