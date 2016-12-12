require 'spec_helper'

describe Applitools::Connectivity::ServerConnector do
  describe 'responds to' do
    it 'api_key' do
      expect(subject).to respond_to :api_key, :api_key=
    end
    it 'server_url' do
      expect(subject).to respond_to :server_url, :server_url=
    end
    it 'proxy_settings' do
      expect(subject).to respond_to :proxy, :proxy=
    end
    it 'set_proxy' do
      expect(subject).to respond_to :set_proxy
      expect(subject).to receive :proxy=
      subject.set_proxy nil
    end
    it 'start_session' do
      expect(subject).to respond_to :start_session
    end
    it 'stop_session' do
      expect(subject).to respond_to :stop_session
    end
    it 'match_window' do
      expect(subject).to respond_to :match_window
    end
  end
end
