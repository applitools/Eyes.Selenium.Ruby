require 'eyes_selenium'
Dir['./spec/support/**/*.rb'].sort.each { |f| require f }

RSpec.configure do |config|
  config.before do
    allow_any_instance_of(Applitools::Connectivity::ServerConnector).to receive(:start_session) do
      Applitools::Core::Session.new('dummy_id', 'dummy_url', true)
    end

    allow_any_instance_of(Applitools::Connectivity::ServerConnector).to receive(:stop_session) do
      Applitools::Core::TestResults.new
    end

    allow_any_instance_of(Applitools::Connectivity::ServerConnector).to receive(:match_window) do
      true
    end
  end
end
