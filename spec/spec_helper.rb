require 'eyes_selenium'

RSpec.configure do |config|
  config.before do
    allow_any_instance_of(Applitools::Selenium::ServerConnector).to receive(:start_session) do
      Applitools::Selenium::Session.new('dummy_id', 'dummy_url', true )
    end

    allow_any_instance_of(Applitools::Selenium::ServerConnector).to receive(:stop_session) do
      Applitools::Selenium::TestResults.new()
    end

    allow_any_instance_of(Applitools::Selenium::ServerConnector).to receive(:match_window) do
      true
    end
  end
end



