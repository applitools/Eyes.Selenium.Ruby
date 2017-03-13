require 'base64'
module Applitools::Core
  class MatchWindowTask
    MATCH_INTERVAL = 0.5
    AppOuptut = Struct.new(:title, :screenshot64)

    attr_reader :logger, :running_session, :default_retry_timeout, :app_output_provider

    def initialize(logger, running_session, retry_timeout, app_output_provider)
      @logger = logger
      @running_session = running_session
      # @driver = driver
      @default_retry_timeout = retry_timeout
      @app_output_provider = app_output_provider

      ArgumentGuard.not_nil logger, 'logger'
      ArgumentGuard.not_nil running_session, 'running_session'
      ArgumentGuard.not_nil app_output_provider, 'app_output_provider'
      ArgumentGuard.greater_than_or_equal_to_zero retry_timeout, 'retry_timeout'

      return if app_output_provider.respond_to? :app_output
      raise Applitools::EyesIllegalArgument.new 'MatchWindowTask.new(): app_output_provider doesn\'t' /
        ' respond to :app_output'
    end

    def match_window(options = {})
      user_inputs = options[:user_inputs]
      last_screenshot = options[:last_screenshot]
      region_provider = options[:region_provider]
      tag = options[:tag]
      should_match_window_run_once_on_timeout = options[:should_match_window_run_once_on_timeout]
      ignore_mismatch = options[:ignore_mismatch]
      retry_timeout = options[:retry_timeout]

      retry_timeout = default_retry_timeout if retry_timeout < 0

      logger.info "retry_timeout = #{retry_timeout}"
      elapsed_time_start = Time.now

      if retry_timeout.zero? || should_match_window_run_once_on_timeout
        sleep retry_timeout if should_match_window_run_once_on_timeout
        app_output = app_output_provider.app_output region_provider, last_screenshot
        match_result = perform_match user_inputs: user_inputs, app_output: app_output, tag: tag,
          ignore_mismatch: ignore_mismatch
      else
        app_output = app_output_provider.app_output region_provider, last_screenshot
        start = Time.now
        match_result = perform_match user_inputs: user_inputs, app_output: app_output, tag: tag, ignore_mismatch: true
        retry_time = Time.now - start

        while retry_time < retry_timeout && !match_result.as_expected?
          sleep MATCH_INTERVAL
          app_output = app_output_provider.app_output region_provider, last_screenshot
          match_result = perform_match user_inputs: user_inputs, app_output: app_output, tag: tag, ignore_mismatch: true
          retry_time = Time.now - start
        end

        unless match_result.as_expected?
          app_output = app_output_provider.app_output region_provider, last_screenshot
          match_result = perform_match user_inputs: user_inputs, app_output: app_output, tag: tag,
            ignore_mismatch: ignore_mismatch
        end
      end

      elapsed_time = (Time.now - elapsed_time_start) / 1000

      logger.info "Completed in #{format('%.2f', elapsed_time)} seconds"

      match_result.screenshot = app_output.screenshot
      match_result
    end

    private

    def perform_match(options = {})
      user_inputs = options[:user_inputs]
      app_output = options[:app_output]
      tag = options[:tag]
      ignore_mismatch = options[:ignore_mismatch]
      data = Applitools::Core::MatchWindowData.new user_inputs, app_output, tag, ignore_mismatch,
        tag: tag, user_inputs: user_inputs, ignore_mismatch: ignore_mismatch, ignore_match: false,
        force_mistmatch: false, force_match: false
      Applitools::Connectivity::ServerConnector.match_window running_session, data
    end
  end
end
