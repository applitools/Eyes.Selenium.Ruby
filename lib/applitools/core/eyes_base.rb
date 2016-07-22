require 'applitools/core/helpers'
module Applitools::Core
  class EyesBase
    extend Forwardable
    extend Applitools::Core::Helpers

    DEFAULT_MATCH_TIMEOUT = 2 #seconds
    USE_DEFAULT_TIMEOUT = -1


    def_delegators 'Applitools::EyesLogger', :logger, :log_handler, :log_handler=
    def_delegators 'Applitools::Connectivity::ServerConnector', :api_key, :api_key=, :server_url, :server_url=, :set_proxy,
                   :proxy, :proxy=

    attr_accessor :app_name, :baseline_name, :branch_name, :parent_branch_name, :batch, :agent_id
    attr_accessor :match_timeout, :save_new_tests, :save_failed_tests, :failure_reports, :default_match_settings, :scale_ratio, :scale_method,
        :host_os, :host_app, :base_line_name, :position_provider

    abstract_attr_accessor :base_agent_id, :viewport_size

    def initialize(server_url = nil)
      Applitools::Connectivity::ServerConnector.server_url = server_url
      self.disabled = false
      @viewport_size = nil
      self.match_timeout = DEFAULT_MATCH_TIMEOUT
      self.running_session = nil
      self.save_new_tests = true
      self.save_failed_tests = false
      self.agent_id = nil
      self.last_screenshot = nil

      # scaleProviderHandler = new SimplePropertyHandler<>();
      # scaleProviderHandler.set(new NullScaleProvider());
      # cutProviderHandler = new SimplePropertyHandler<>();
      # cutProviderHandler.set(new NullCutProvider());
      #
      # positionProvider = new InvalidPositionProvider();
      # scaleMethod = ScaleMethod.getDefault();
      #
      # defaultMatchSettings = new ImageMatchSettings();
      # failureReports = FailureReports.ON_CLOSE;
      # userInputs = new ArrayDeque<>();

    end

    def full_agent_id
      if agent_id && agent_id.present?
        "#{agent_id} [#{base_agent_id}]"
      else
        base_agent_id
      end
    end

    def disabled=(value)
      @disabled = Applitools::Utils.boolean_value value
    end

    def disabled?
      @disabled
    end

    def open?
      @open
    end

    def abort_if_not_closed
      if disabled?
        logger.info "Ignored"
        return
      end

      self.open = false
      self.last_screenshot = nil
      clear_user_inputs

      if running_session.nil?
        logger.info "Closed"
        return
      end

      logger.info 'Aborting server session...'
      Applitools::Connectivity::ServerConnector.stop_session(running_session, true, false)
      logger.info '---Test aborted'

    rescue Applitools::EyesError => e
      logger.error e.message
    ensure
      self.running_session = nil
    end

    def open_base(options)
      if disabled?
        logger.info "Ignored"
        return
      end

      Applitools::Core::ArgumentGuard.hash options, 'open_base parameter', [:test_name]
      default_options = {session_type: 'SEQUENTAL'}
      options = default_options.merge options

      if app_name.nil?
        Applitools::Core::ArgumentGuard.not_nil options[:app_name], 'options[:app_name]'
        self.current_app_name = options[:app_name]
      else
        self.current_app_name = app_name
      end

      Applitools::Core::ArgumentGuard.not_nil options[:test_name], 'options[:test_name]'
      self.test_name = options[:test_name];

      logger.info "Agent = #{full_agent_id}"
      logger.info "openBase(app_name: #{options[:app_name]}, test_name: #{options[:test_name]}," \
          " viewport_size: #{options[:viewport_size]})"

      raise Applitools::EyesError.new 'API key is missing! Please set it using api_key=' if self.api_key.nil?

      if open?
        abort_if_not_closed
        raise Applitools::EyesError.new 'A test is already running'
      end



      self.viewport_size = viewport_size;
      self.session_type = session_type

      # scaleProviderHandler.set(new NullScaleProvider());
      # setScaleMethod(ScaleMethod.getDefault());

      self.open = true;

    rescue Applitools::EyesError => e
      logger.error e.message
      raise e
    end

    def close(throw_exception = false)

      if disabled?
        logger.info "Ignored"
        return
      end

      logger.info "close(#{throw_exception})"
      raise Applitools::EyesError.new 'Eyes not open' unless open?

      self.open = false
      self.last_screenshot = nil

      clear_user_inputs

      unless running_session
        logger.info 'Server session was not started'
        logger.info '--- Empty test ended'
        return Applitools::Core::TestResults.new
      end

      is_new_session = running_session.new_session?
      session_results_url = running_session.url

      logger.info 'Ending server session...'

      save = is_new_session && save_new_tests || !is_new_session && save_failed_tests

      logger.info "Automatically save test? #{save}"

      results = Applitools::Connectivity::ServerConnector.stop_session running_session, false, save

      results.is_new = is_new_session
      results.url = session_results_url

      logger.info results

      if results.failed?
        logger.error "--- Failed test ended. see details at #{session_results_url}"
        error_message = "#{session_start_info.scenario_id_or_name} of #{session_start_info.app_id_or_name}. " \
            "See details at #{session_results_url}."
        raise Applitools::TestFailedError.new error_message, results if throw_exception
        return results
      end

      if results.new?
        instructions = "Please approve the new baseline at #{session_results_url}"
        logger.info "--- New test ended. #{instructions}"
        error_message = "#{session_start_info.scenario_id_or_name} of #{session_start_info.app_id_or_name}. " \
            "#{instructions}"
        raise Applitools::TestFailedError.new error_message, results if throw_exception
        return results
      end

      logger.info "--- Test passed"
      return results
    ensure
      self.running_session = nil
      self.current_app_name = nil
    end

    private

    attr_accessor :running_session, :last_screenshot, :current_app_name, :test_name, :session_type,
                  :full_agent_id, :scale_provider_handler, :cut_provider_handler, :default_match_settings,
                  :session_start_info

    def app_environment
      result = Applitools::AppEnvironment.new
      result.host_os = host_os if host_os
      result.
    end

    def open=(value)
      @open = Applitools::Utils.boolean_value value
    end

    def clear_user_inputs

    end

    def start_session
      logger.info 'start_session()'

      #FIXME: looks strange
      unless @viewport_size
        @viewport_size = viewport_size
      else
        self.viewport_size = @viewport_size
      end

      if batch.nil?
        logger.info 'No batch set'
        test_batch = BatchInfo.new
      else
        logger.info "Batch is #{batch}"
        test_batch = batch
      end

      app_env = app_environment
      # AppEnvironment appEnv = getAppEnvironment();
      # logger.verbose("Application environment is " + appEnv);
      #
      # sessionStartInfo = new SessionStartInfo(getBaseAgentId(), sessionType,
      #                                         getAppName(), null, testName, testBatch, baselineName, appEnv,
      #                                         defaultMatchSettings, branchName, parentBranchName);
      #
      # logger.verbose("Starting server session...");
      # runningSession = serverConnector.startSession(sessionStartInfo);
      #
      # logger.verbose("Server session ID is " + runningSession.getId());
      #
      # String testInfo = "'" + testName + "' of '" + getAppName() + "' " +
      #     appEnv;
      # if (runningSession.getIsNewSession()) {
      #     logger.log("--- New test started - " + testInfo);
      # shouldMatchWindowRunOnceOnTimeout = true;
      # } else {
      #     logger.log("--- Test started - " + testInfo);
      # shouldMatchWindowRunOnceOnTimeout = false;
      # }

    end

  end
end

