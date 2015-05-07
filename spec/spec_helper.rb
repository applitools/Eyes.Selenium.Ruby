require 'eyes_selenium'
require 'pry'

STATIC_FILE = "file://#{File.dirname(__FILE__)}/fixtures/static_test_file.html"

RSpec.configure do |config|
  config.before do
    #mocks out connection to Applitools.
    allow_any_instance_of(Applitools::AgentConnector).to receive(:start_session) do
      Applitools::Session.new('dummy_id', 'dummy_url', true )
    end

    allow_any_instance_of(Applitools::AgentConnector).to receive(:stop_session) do
      Applitools::TestResults.new()
    end

    allow_any_instance_of(Applitools::AgentConnector).to receive(:match_window) do
      true
    end
  end
end



