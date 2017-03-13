require 'applitools/core/helpers'
require 'applitools/core/eyes_screenshot'

module Applitools::Core
  class EyesBase
    extend Forwardable
    extend Applitools::Core::Helpers

    DEFAULT_MATCH_TIMEOUT = 2 # seconds
    USE_DEFAULT_TIMEOUT = -1

    SCREENSHOT_AS_IS = Applitools::Core::EyesScreenshot::COORDINATE_TYPES[:screenshot_as_is].freeze
    CONTEXT_RELATIVE = Applitools::Core::EyesScreenshot::COORDINATE_TYPES[:context_relative].freeze

    MATCH_LEVEL = {
      none: 'None',
      layout: 'Layout',
      layout2: 'Layout2',
      content: 'Content',
      strict: 'Strict',
      exact: 'Exact'
    }.freeze

    def_delegators 'Applitools::EyesLogger', :logger, :log_handler, :log_handler=
    def_delegators 'Applitools::Connectivity::ServerConnector', :api_key, :api_key=, :server_url, :server_url=,
      :set_proxy, :proxy, :proxy=

    # @!attribute [rw] verbose_results
    #   If set to true it will display test results in verbose format, including all fields returned by the server
    #   Default value is false.
    #   @return [boolean] verbose_results flag

    attr_accessor :app_name, :baseline_name, :branch_name, :parent_branch_name, :batch, :agent_id, :full_agent_id,
      :match_timeout, :save_new_tests, :save_failed_tests, :failure_reports, :default_match_settings, :cut_provider,
      :scale_ratio, :host_os, :host_app, :base_line_name, :position_provider, :viewport_size, :verbose_results

    abstract_attr_accessor :base_agent_id, :inferred_environment
    abstract_method :capture_screenshot, true
    abstract_method :title, true
    abstract_method :set_viewport_size, true
    abstract_method :get_viewport_size, true

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
      @user_inputs = UserInputArray.new
      self.app_output_provider = Object.new
      self.verbose_results = false

      get_app_output_method = ->(r, s) { get_app_output_with_screenshot r, s }

      app_output_provider.instance_eval do
        define_singleton_method :app_output do |r, s|
          get_app_output_method.call(r, s)
        end
      end

      self.default_match_settings = MATCH_LEVEL[:exact]
    end

    def full_agent_id
      if !agent_id.nil? && !agent_id.empty?
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

    def app_name
      !current_app_name.nil? && !current_app_name.empty? ? current_app_name : @app_name
    end

    def abort_if_not_closed
      if disabled?
        logger.info "#{__method__} Ignored"
        return
      end

      self.open = false
      self.last_screenshot = nil
      clear_user_inputs

      if running_session.nil?
        logger.info 'Closed'
        return
      end

      logger.info 'Aborting server session...'
      Applitools::Connectivity::ServerConnector.stop_session(running_session, true, false)
      logger.info '---Test aborted'

    rescue Applitools::EyesError => e
      logger.error e.messages

    ensure
      self.running_session = nil
    end

    def open_base(options)
      if disabled?
        logger.info "#{__method__} Ignored"
        return
      end

      Applitools::Core::ArgumentGuard.hash options, 'open_base parameter', [:test_name]
      default_options = { session_type: 'SEQUENTAL' }
      options = default_options.merge options

      if app_name.nil?
        Applitools::Core::ArgumentGuard.not_nil options[:app_name], 'options[:app_name]'
        self.current_app_name = options[:app_name]
      else
        self.current_app_name = app_name
      end

      Applitools::Core::ArgumentGuard.not_nil options[:test_name], 'options[:test_name]'
      self.test_name = options[:test_name]
      logger.info "Agent = #{full_agent_id}"
      logger.info "openBase(app_name: #{options[:app_name]}, test_name: #{options[:test_name]}," \
          " viewport_size: #{options[:viewport_size]})"

      raise Applitools::EyesError.new 'API key is missing! Please set it using api_key=' if api_key.nil?

      if open?
        abort_if_not_closed
        raise Applitools::EyesError.new 'A test is already running'
      end

      self.viewport_size = options[:viewport_size]
      self.session_type = options[:session_type]

      self.open = true
    rescue Applitools::EyesError => e
      logger.error e.message
      raise e
    end

    def check_window_base(region_provider, tag, ignore_mismatch, retry_timeout)
      if disabled?
        logger.info "#{__method__} Ignored"
        result = Applitools::Core::MatchResults.new
        result.as_expected = true
        return result
      end

      raise Applitools::EyesError.new 'Eyes not open' unless open?
      Applitools::Core::ArgumentGuard.not_nil region_provider, 'region_provider'

      logger.info "check_window_base(#{region_provider}, #{tag}, #{ignore_mismatch}, #{retry_timeout})"

      tag = '' if tag.nil?

      if running_session.nil?
        logger.info 'No running session, calling start session..'
        start_session
        logger.info 'Done!'
        @match_window_task = Applitools::Core::MatchWindowTask.new(
          logger,
          running_session,
          match_timeout,
          app_output_provider
        )
      end

      logger.info 'Calling match_window...'
      result = @match_window_task.match_window(
        user_inputs: user_inputs,
        last_screenshot: last_screenshot,
        region_provider: region_provider,
        tag: tag,
        should_match_window_run_once_on_timeout: should_match_window_run_once_on_timeout,
        ignore_mismatch: ignore_mismatch,
        retry_timeout: retry_timeout
      )
      logger.info 'match_window done!'

      if result.as_expected?
        clear_user_inputs
        self.last_screenshot = result.screenshot
      else
        unless ignore_mismatch
          clear_user_inputs
          self.last_screenshot = result.screenshot
        end

        self.should_match_window_run_once_on_timeout = true

        logger.info "Mistmatch! #{tag}" unless running_session.new_session?

        if failure_reports == :immediate
          raise Applitools::TestFailedException.new "Mistmatch found in #{session_start_info.scenario_id_or_name}" \
              " of #{session_start_info.app_id_or_name}"
        end
      end

      logger.info 'Done!'
      result
    end

    # Closes eyes
    # @param [Boolean] throw_exception If set to +true+ eyes will trow [Applitools::TestFailedError] exception,
    # otherwise the test will pass. Default is true

    def close(throw_exception = true)
      if disabled?
        logger.info "#{__method__} Ignored"
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

      logger.info results.to_s(verbose_results)

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

      logger.info '--- Test passed'
      return results
    ensure
      self.running_session = nil
      self.current_app_name = nil
    end

    private

    attr_accessor :running_session, :last_screenshot, :current_app_name, :test_name, :session_type,
      :scale_provider, :default_match_settings, :session_start_info,
      :should_match_window_run_once_on_timeout, :app_output_provider

    attr_reader :user_inputs

    private :full_agent_id, :full_agent_id=

    def app_environment
      Applitools::Core::AppEnvironment.new os: host_os, hosting_app: host_app,
          display_size: @viewport_size, inferred: inferred_environment
    end

    def open=(value)
      @open = Applitools::Utils.boolean_value value
    end

    def clear_user_inputs
      @user_inputs.clear
    end

    def add_user_input(trigger)
      if disabled?
        logger.info "#{__method__} Ignored"
        return
      end

      Applitools::Core::ArgumentGuard.not_nil(trigger, 'trigger')
      @user_inputs.add(trigger)
    end

    def add_text_trigger_base(control, text)
      if disabled?
        logger.info "#{__method__} Ignored"
        return
      end

      Applitools::Core::ArgumentGuard.not_nil control, 'control'
      Applitools::Core::ArgumentGuard.not_nil text, 'control'

      control = Applitools::Core::Region.new control.left, control.top, control.width, control.height

      if last_screenshot.nil?
        logger.info "Ignoring '#{text}' (no screenshot)"
        return
      end

      control = last_screenshot.intersected_region control, EyesScreenshot::COORDINATE_TYPES[:context_relative],
        EyesScreenshot::COORDINATE_TYPES[:screenshot_as_is]

      if control.empty?
        logger.info "Ignoring '#{text}' out of bounds"
        return
      end

      trigger = Applitools::Core::TextTrigger.new text, control
      add_user_input trigger
      logger.info "Added '#{trigger}'"
    end

    def add_mouse_trigger_base(action, control, cursor)
      if disabled?
        logger.info "#{__method__} Ignored"
        return
      end

      Applitools::Core::ArgumentGuard.not_nil action, 'action'
      Applitools::Core::ArgumentGuard.not_nil control, 'control'
      Applitools::Core::ArgumentGuard.not_nil cursor, 'cursor'

      if last_screenshot.nil?
        logger.info "Ignoring '#{action}' (no screenshot)"
        return
      end

      cursor_in_screenshot = Applitools::Core::Location.new cursor.x, cursor.y
      cursor_in_screenshot.offset(control)

      begin
        cursor_in_screenshot = last_screenshot.location_in_screenshot cursor_in_screenshot, CONTEXT_RELATIVE
      rescue Applitools::OutOfBoundsException
        logger.info "Ignoring #{action} (out of bounds)"
        return
      end

      control_screenshot_intersect = last_screenshot.intersected_region control, CONTEXT_RELATIVE, SCREENSHOT_AS_IS

      unless control_screenshot_intersect.empty?
        l = control_screenshot_intersect.location
        cursor_in_screenshot.offset Applitools::Core::Location.new(-l.x, -l.y)
      end

      trigger = Applitools::Core::MouseTrigger.new action, control_screenshot_intersect, cursor_in_screenshot
      add_user_input trigger

      logger.info "Added #{trigger}"
    end

    def start_session
      logger.info 'start_session()'

      if viewport_size
        set_viewport_size(viewport_size)
      else
        self.viewport_size = get_viewport_size
      end

      if batch.nil?
        logger.info 'No batch set'
        test_batch = BatchInfo.new
      else
        logger.info "Batch is #{batch}"
        test_batch = batch
      end

      app_env = app_environment

      logger.info "Application environment is #{app_env}"

      self.session_start_info = SessionStartInfo.new agent_id: base_agent_id, app_id_or_name: app_name,
                                                scenario_id_or_name: test_name, batch_info: test_batch,
                                                env_name: baseline_name, environment: app_env,
                                                default_match_settings: default_match_settings,
                                                match_level: default_match_settings,
                                                branch_name: branch_name, parent_branch_name: parent_branch_name

      logger.info 'Starting server session...'
      self.running_session = Applitools::Connectivity::ServerConnector.start_session session_start_info

      logger.info "Server session ID is #{running_session.id}"
      test_info = "'#{test_name}' of '#{app_name}' #{app_env}"
      if running_session.new_session?
        logger.info "--- New test started - #{test_info}"
        self.should_match_window_run_once_on_timeout = true
      else
        logger.info "--- Test started - #{test_info}"
        self.should_match_window_run_once_on_timeout = false
      end
    end

    def get_app_output_with_screenshot(region_provider, last_screenshot)
      logger.info 'Getting screenshot...'
      screenshot = capture_screenshot
      logger.info 'Done getting screenshot!'
      region = region_provider.region

      unless region.empty?
        screenshot = screenshot.sub_screenshot region, region_provider.coordinate_type, false
      end

      logger.info 'Compressing screenshot...'
      compress_result = compress_screenshot64 screenshot, last_screenshot
      logger.info 'Done! Getting title...'
      a_title = title
      logger.info 'Done!'
      Applitools::Core::AppOutputWithScreenshot.new(
        Applitools::Core::AppOutput.new(a_title, compress_result),
        screenshot
      )
    end

    def compress_screenshot64(screenshot, _last_screenshot)
      screenshot # it is a stub
    end

    class UserInputArray < Array
      def add(trigger)
        raise Applitools::EyesIllegalArgument.new 'trigger must be kind of Trigger!' unless trigger.is_a? Trigger
        self << trigger
      end

      def to_hash
        map do |trigger|
          trigger.to_hash if trigger.respond_to? :to_hash
        end.compact
      end
    end
  end
end
