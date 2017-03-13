require 'spec_helper'

RSpec.shared_examples 'can be disabled' do |method_name, arguments|
  before do
    expect(subject).to receive(:disabled?).and_return(true).at_least(1)
    expect(subject.logger).to receive(:info).with("#{method_name} Ignored").at_least(1)
  end
  it 'checks disabled? flag and logs \'Ignored\'' do
    subject.send(method_name, *arguments)
  end
end

describe Applitools::Core::EyesBase do
  it_should_behave_like 'responds to method', [
    :agent_id,
    :agent_id=,
    :api_key,
    :api_key=,
    :server_url,
    :server_url=,
    :proxy, :proxy=,
    :disabled?,
    :disabled=,
    :app_name,
    :app_name=,
    :branch_name,
    :branch_name=,
    :parent_branch_name,
    :parent_branch_name=,
    :match_timeout,
    :match_timeout=,
    :save_new_tests,
    :save_new_tests=,
    :save_failed_tests,
    :save_failed_tests=,
    :batch,
    :batch=,
    :failure_reports,
    :failure_reports=,
    :open?,
    :log_handler,
    :log_handler=,
    :scale_ratio,
    :scale_ratio=,
    :close,
    :abort_if_not_closed,
    :host_os,
    :host_os=,
    :host_app,
    :host_app=,
    :base_line_name,
    :base_line_name=,
    :position_provider,
    :position_provider=,
    :open_base,
    :check_window_base,
    :cut_provider,
    :cut_provider=
  ]

  it_should_behave_like 'has private method', [
    :clear_user_inputs,
    :user_inputs,
    :start_session,
    :base_agent_id,
    :default_match_settings,
    :default_match_settings=
    # :close_response_time
  ]

  it_should_behave_like 'proxy method', Applitools::Connectivity::ServerConnector, [
    :api_key,
    :api_key=,
    :server_url,
    :server_url=,
    :proxy,
    :proxy=,
    :set_proxy
  ]

  it_should_behave_like 'proxy method', Applitools::EyesLogger, [:logger, :log_handler, :log_handler=]

  it_should_behave_like 'has abstract method', [:base_agent_id]

  it 'initializes variables' do
    expect(subject.send(:disabled?)).to eq false
    expect(subject.instance_variable_get(:@viewport_size)).to be_nil
    expect(subject.send(:running_session)).to be_nil
    expect(subject.send(:last_screenshot)).to be_nil
    expect(subject.send(:agent_id)).to be_nil
    expect(subject.send(:save_new_tests)).to eq true
    expect(subject.send(:save_failed_tests)).to eq false
    expect(subject.send(:match_timeout)).to eq Applitools::Core::EyesBase::DEFAULT_MATCH_TIMEOUT
  end

  context 'abort_if_not_closed' do
    it_behaves_like 'can be disabled', :abort_if_not_closed
    context do
      before do
        expect(subject).to receive(:disabled?).and_return false
        expect(Applitools::Connectivity::ServerConnector).to receive(:stop_session).and_return true
        Applitools::Connectivity::ServerConnector.server_url = nil
        subject.send(:running_session=, Applitools::Core::Session.new('id', 'url', true))
      end

      after do
        subject.abort_if_not_closed
      end

      it 'calls ServerConnector.stop_session' do
      end

      it 'clears user inputs' do
        expect(subject).to receive :clear_user_inputs
      end

      it 'clears last screenshot' do
        expect(subject).to receive(:last_screenshot=).with(nil)
      end

      it 'drops running session' do
        expect(subject).to receive(:running_session=).with(nil)
      end
    end
  end

  context 'open_base()' do
    before do
      allow(subject).to receive(:base_agent_id).and_return nil
    end

    it_behaves_like 'can be disabled', :open_base, [:test_name => :test_name]

    context 'when api_key present' do
      before do
        expect(subject).to receive(:api_key).and_return :value
      end

      it 'validates presence of app_name' do
        expect { subject.open_base(:test_name => :test_name) }.to raise_error(Applitools::EyesIllegalArgument)
        expect(subject).to receive(:viewport_size=)
        subject.app_name = :test
        subject.open_base(:test_name => :test)
        expect(subject.send(:test_name)).to eq :test
      end

      it 'validates presence of test_name' do
        expect(subject).to receive(:viewport_size=)
        expect { subject.open_base(:app_name => :app_name) }.to raise_error(Applitools::EyesIllegalArgument)
        subject.open_base(:app_name => :app_name, :test_name => :test)
      end

      it 'set open? to true' do
        expect(subject).to receive(:viewport_size=)
        subject.send(:open=, false)
        subject.open_base :app_name => :a, :test_name => :b, :viewport_size => :c, :session_type => :d
        expect(subject.open?).to eq true
      end

      it 'aborts the test if already running' do
        subject.send(:open=, true)
        expect(subject).to receive :abort_if_not_closed
        expect { subject.open_base(:app_name => :app, :test_name => :test) }.to raise_error(Applitools::EyesError,
          'A test is already running')
      end
    end

    it 'throws exception without API key' do
      subject.api_key = nil
      expect { subject.open_base(:app_name => :test, :test_name => :test) }.to raise_error(Applitools::EyesError,
        'API key is missing! Please set it using api_key=')
    end
  end

  it 'Implements start_session()' do
    expect(subject.private_methods).to include :start_session
  end

  context 'start_session()' do
  end

  context 'close()' do
    it_behaves_like 'can be disabled', :close, [false]

    let(:success_old_results) do
      Applitools::Core::TestResults.new 'steps' => 5, 'matches' => 5, 'mismatches' => 0, 'missing' => 0
    end

    let(:failed_old_results) do
      Applitools::Core::TestResults.new 'steps' => 5, 'matches' => 1, 'mismatches' => 2, 'missing' => 2
    end

    let(:new_results) do
      new = Applitools::Core::TestResults.new
      new.is_new = true
      new.url = 'http://see.results.url'
      new
    end

    let(:r_session) { Applitools::Core::Session.new :session_id, :session_url, false }
    let(:r_session_new) { Applitools::Core::Session.new :session_id, :session_url, true }

    before do
      subject.instance_variable_set :@running_session, r_session
      subject.instance_variable_set :@current_app_name, :stub
      subject.instance_variable_set :@open, true
    end

    it 'drops running session' do
      expect(Applitools::Connectivity::ServerConnector).to receive(:stop_session).and_return(success_old_results)
      subject.close(false)
      expect(subject.instance_variable_get(:@running_session)).to be_nil
    end

    it 'drops current_app_name' do
      expect(Applitools::Connectivity::ServerConnector).to receive(:stop_session).and_return(success_old_results)
      subject.close(false)
      expect(subject.instance_variable_get(:@current_app_name)).to be_nil
    end

    it 'clears user inputs' do
      expect(Applitools::Connectivity::ServerConnector).to receive(:stop_session).and_return(success_old_results)
      expect(subject).to receive :clear_user_inputs
      subject.close(true)
    end

    it 'trows an exception while is not open' do
      subject.instance_variable_set :@open, false
      expect { subject.close(false) }.to raise_error Applitools::EyesError
    end

    it 'returns empty result if no session started' do
      subject.instance_variable_set :@running_session, nil
      close_result = subject.close(true)
      expect(close_result).to be_a Applitools::Core::TestResults
      expect(close_result).to eq Applitools::Core::TestResults.new
    end

    it 'calls Applitools::Connectivity::ServerConnector.stop_session' do
      expect(Applitools::Connectivity::ServerConnector).to receive(:stop_session).and_return(success_old_results)
      subject.close(true)
    end

    it 'sets new flag for results' do
      expect(Applitools::Connectivity::ServerConnector).to receive(:stop_session).and_return(success_old_results)
      result = subject.close(false)
      expect(result.new?).to eq false
    end

    it 'sets server_url for results' do
      expect(Applitools::Connectivity::ServerConnector).to receive(:stop_session).and_return(success_old_results)
      result = subject.close(false)
      expect(result.url).to eq :session_url
    end

    context 'throws an exception for failed test if called like close(true)' do
      before do
        expect(subject).to receive(:session_start_info).and_return(
          Applitools::Core::SessionStartInfo.new(
            :agent_id => :a,
            :app_id_or_name => :b,
            :ver_id => :c,
            :scenario_id_or_name => :d,
            :batch_info => :e,
            :env_name => :f,
            :environment => :g
          )
        ).at_least 1
      end

      it 'failed test close(true)' do
        expect(subject).to receive(:open?).and_return(true).at_least 1
        expect(Applitools::Connectivity::ServerConnector).to receive(:stop_session).and_return(failed_old_results)
        expect { subject.close(true) }.to raise_error Applitools::TestFailedError
      end

      it 'new test close(true)' do
        expect(subject).to receive(:open?).and_return(true).at_least 1
        expect(subject).to receive(:running_session).and_return(r_session_new).at_least 1
        expect(Applitools::Connectivity::ServerConnector).to receive(:stop_session).and_return(new_results)
        expect { subject.close(true) }.to raise_error Applitools::TestFailedError
      end
    end

    context 'don\'t throw exception when called like close(false)' do
      before do
        expect(subject).to receive(:session_start_info).and_return(
          Applitools::Core::SessionStartInfo.new(
            :agent_id => :a,
            :app_id_or_name => :b,
            :ver_id => :c,
            :scenario_id_or_name => :d,
            :batch_info => :e,
            :env_name => :f,
            :environment => :g
          )
        ).at_least 1
      end

      it 'failed test close(false)' do
        expect(subject).to receive(:open?).and_return(true).at_least 1
        expect(Applitools::Connectivity::ServerConnector).to receive(:stop_session).and_return(failed_old_results)
        subject.close(false)
      end
      it 'new test close (false)' do
        expect(subject).to receive(:open?).and_return(true).at_least 1
        expect(subject).to receive(:running_session).and_return(r_session_new).at_least 1
        expect(Applitools::Connectivity::ServerConnector).to receive(:stop_session).and_return(new_results)
        subject.close(false)
      end
    end
  end

  context 'start session' do
    it 'a private method' do
      expect { subject.start_session }.to raise_error NoMethodError
    end
    it 'calls ServerConnector.start_session' do
      expect(Applitools::Connectivity::ServerConnector).to receive(:start_session).and_return(
        Applitools::Core::Session.new(:session_id, :session_url, true)
      )
      expect(subject).to receive(:viewport_size).and_return nil
      expect(subject).to receive(:get_viewport_size).and_return Applitools::Core::RectangleSize.new(1024, 768)
      expect(subject).to receive(:inferred_environment).and_return nil
      expect(subject).to receive(:base_agent_id).and_return nil
      subject.send :start_session
    end
  end

  context 'match_window_base' do
    it_behaves_like 'can be disabled', :check_window_base, [nil, nil, nil, nil]
  end
end
