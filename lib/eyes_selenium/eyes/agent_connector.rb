require 'httparty'
class Applitools::AgentConnector
  include HTTParty
  headers 'Accept' => 'application/json'
  ssl_ca_file File.join(File.dirname(File.expand_path(__FILE__)), '../../../certs/cacert.pem').to_s
  default_timeout 300
  #debug_output $stdout # comment out when not debugging

  attr_reader :uri, :auth
  def initialize(base_uri, username, password)
    # Remove trailing slashes in base uri and add the running sessions endpoint uri.
    @uri = base_uri.gsub(/\/$/,"") + "/api/sessions/running"
    @auth = { username: username, password: password }
  end

  def match_window(session, data)
    self.class.headers 'Content-Type' => 'application/octet-stream'
    json_data = data.to_hash.to_json.force_encoding('BINARY') # Notice that this does not include the screenshot
    body = [json_data.length].pack('L>') + json_data + data.screenshot

    res = self.class.post(uri + "/#{session.id}",basic_auth: auth, body: body)
    raise Applitools::EyesError.new("could not connect to server") if res.code != 200
    res.parsed_response["asExpected"]
  end

  def start_session(session_start_info)
   self.class.headers 'Content-Type' => 'application/json'
   res = self.class.post(uri, basic_auth: auth, body: { startInfo: session_start_info.to_hash }.to_json)
   status_code = res.response.message
   parsed_res = res.parsed_response
   Applitools::Session.new(parsed_res["id"], parsed_res["url"], status_code == "Created" )
  end

  def stop_session(session, aborted=nil, save=false)
    self.class.headers 'Content-Type' => 'application/json'
    res = self.class.send_long_request('stop_session') do
        self.class.delete(uri + "/#{session.id}", basic_auth: auth, query: { aborted: aborted.to_s, updateBaseline: save.to_s })
    end
    parsed_res = res.parsed_response
    parsed_res.delete("$id")
    Applitools::TestResults.new(*parsed_res.values)
  end

  private
  ##
  # Static method for sending long running requests
  # Args:
  #   name: (String) name of the method being executed
  #   request_block: (block) The actual block to be executed. Will be called using "yield"
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
      EyesLogger.debug "#{name}: Still running... Retrying in #{delay}s"
      sleep delay
      delay = [10, (delay*1.5).round].min
    end
  end
end
