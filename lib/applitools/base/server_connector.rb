require 'faraday'

module Applitools::Base::ServerConnector
  extend self

  DEFAULT_SERVER_URL = 'https://eyessdk.applitools.com'.freeze

  SSL_CERT = File.join(File.dirname(File.expand_path(__FILE__)), '../../../certs/cacert.pem').to_s.freeze
  DEFAULT_TIMEOUT = 300.freeze

  API_SESSIONS_RUNNING =  '/api/sessions/running/'.freeze

  HTTP_STATUS_CODES = {
    created: 201,
    accepted: 202
  }.freeze

  attr_accessor :server_url, :api_key
  attr_reader :endpoint_url

  def server_url=(url)
    @server_url = url.nil? ? DEFAULT_SERVER_URL : url
    @endpoint_url = URI.join(@server_url, API_SESSIONS_RUNNING).to_s
  end

  def match_window(session, data)
    json_data = data.to_hash.to_json.force_encoding('BINARY') # Notice that this does not include the screenshot
    body = [json_data.length].pack('L>') + json_data + data.screenshot

    Applitools::EyesLogger.debug 'Sending match data...'

    res = post(URI.join(endpoint_url, session.id.to_s), content_type: 'application/octet-stream', body: body)
    raise Applitools::EyesError.new("Request failed: #{res.status}") unless res.success?

    JSON.parse(res.body)['asExpected'].tap do |as_expected|
      Applitools::EyesLogger.debug "Got response! #{as_expected}"
    end
  end

  def start_session(session_start_info)
    res = post(endpoint_url, body: {startInfo: session_start_info.to_hash}.to_json)
    raise Applitools::EyesError.new("Request failed: #{res.status}") unless res.success?

    response = JSON.parse(res.body)
    Applitools::Base::Session.new(response['id'], response['url'], res.status == HTTP_STATUS_CODES[:created])
  end

  def stop_session(session, aborted = nil, save = false)
    res = long_delete(URI.join(endpoint_url, session.id.to_s), query: {aborted: aborted, updateBaseline: save})
    raise Applitools::EyesError.new("Request failed: #{res.status}") unless res.success?

    response = JSON.parse(res.body)
    response.delete('$id')
    Applitools::Base::TestResults.new(*response.values)
  end

  private

  DEFAULT_HEADERS = {
    'Accept' => 'application/json',
    'Content-Type' => 'application/json'
  }.freeze

  LONG_REQUEST_DELAY = 2.freeze # seconds
  MAX_LONG_REQUEST_DELAY = 10.freeze # seconds
  LONG_REQUEST_DELAY_MULTIPLICATIVE_INCREASE_FACTOR = 1.5.freeze

  [:get, :post, :delete].each do |method|
    define_method method do |url, options = {}|
      request(url, method, options)
    end

    define_method "long_#{method}" do |url, options = {}|
      long_request(url, method, options)
    end
  end

  def request(url, method, options = {})
    Faraday::Connection.new(url, ssl: {ca_file: SSL_CERT}).send(method) do |req|
      req.options.timeout  = DEFAULT_TIMEOUT
      req.headers = DEFAULT_HEADERS.merge(options[:headers] || {})
      req.headers['Content-Type'] = options[:content_type] if options.key?(:content_type)
      req.params = {apiKey: api_key}.merge(options[:query] || {})
      req.body = options[:body]
    end
  end

  def long_request(url, method, options = {})
    delay = LONG_REQUEST_DELAY
    (options[:headers] ||= {})['Eyes-Expect'] = '202-accepted'

    while true
      # Date should be in RFC 1123 format.
      options[:headers]['Eyes-Date'] = Time.now.utc.strftime('%a, %d %b %Y %H:%M:%S GMT')

      res = request(url, method, options)
      return res unless res.status == HTTP_STATUS_CODES[:accepted]

      Applitools::EyesLogger.debug "Still running... retrying in #{delay}s"
      sleep delay

      delay = [MAX_LONG_REQUEST_DELAY, (delay * LONG_REQUEST_DELAY_MULTIPLICATIVE_INCREASE_FACTOR).round].min
    end
  end

  include Applitools::MethodTracer
end
