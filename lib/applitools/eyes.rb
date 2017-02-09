require 'capybara/poltergeist'

require_relative 'version'
require_relative 'eyes_logger'

require 'forwardable'

class Applitools::Eyes
  extend Forwardable

  FAILURE_REPORTS = {
    immediate: 'Immediate',
    on_close: 'OnClose'
  }.freeze

  MATCH_LEVEL = {
    none: 'None',
    layout: 'Layout',
    layout2: 'Layout2',
    content: 'Content',
    strict: 'Strict',
    exact: 'Exact'
  }.freeze

  DEFAULT_MATCH_TIMEOUT = 2.0 # Seconds
  # noinspection RubyConstantNamingConvention
  DEFAULT_WAIT_BEFORE_SCREENSHOTS = 0.1 # Seconds
  BASE_AGENT_ID = ('eyes.selenium.ruby/' + Applitools::VERSION).freeze

  ANDROID = 'Android'.freeze
  IOS = 'iOS'.freeze

  # Attributes:
  #
  # +app_name+:: +String+ The application name which was provided as an argument to +open+.
  # +test_name+:: +String+ The test name which was provided as an argument to +open+.
  # +is_open+:: +boolean+ Is there an open session.
  # +viewport_size+:: +Hash+ The viewport size which was provided as an argument to +open+. Should include +width+
  #   and +height+.
  # +driver+:: +Applitools::Selenium::Driver+ The driver instance wrapping the driver which was provided as an argument
  #   to +open+.
  # +api_key+:: +String+ The user's API key.
  # +match_timeout+:: +Float+ The default timeout for check_XXXX operations. (Seconds)
  # +batch+:: +BatchInfo+ The current tests grouping, if any.
  # +host_os+:: +String+ A string identifying the OS running the AUT. Set this if you wish to override Eyes' automatic
  #   inference.
  # +host_app+:: +String+ A string identifying the container application running the AUT (e.g., Firefox). Set this if
  #   you wish to override Eyes' automatic inference.
  # +branch_name+:: +String+ If set, names the branch in which the test should run.
  # +parent_branch_name+:: +String+ If set, names the parent branch of the branch in which the test should run.
  # +user_inputs+:: +Applitools::Base::MouseTrigger+/+Applitools::Selenium::KeyboardTrigger+ Mouse/Keyboard events which
  #   happened after the last visual validation.
  # +save_new_tests+:: +boolean+ Whether or not new tests should be automatically accepted as baseline.
  # +save_failed_tests+:: +boolean+ Whether or not failed tests should be automatically accepted as baseline.
  # +match_level+:: +String+ The default match level for the entire session. See +Applitools::Eyes::MATCH_LEVEL+.
  # +baseline_name+:: +String+ A string identifying the baseline which the test will be compared against. Set this if
  #   you wish to override Eyes' automatic baseline inference.
  # +is_disabled+:: +boolean+ Set to +true+ if you wish to disable Eyes without deleting code (Eyes' methods act as a
  #   mock, and will do nothing).
  # +server_url+:: +String+ The Eyes' server. Set this if you wish to override the default Eyes server URL.
  # +agent_id+:: +String+ An optional string identifying the current library using the SDK.
  # +log_handler+:: +Logger+ The logger to which Eyes will send info/debug messages.
  # +failure_reports+:: +String+ Whether the current test will report mismatches immediately or when it is finished.
  #   See +Applitools::Eyes::FAILURE_REPORTS+.
  # +rotation+:: +Integer+|+nil+ The degrees by which to rotate the screenshots received from the driver. Set this to
  #   override Eyes' automatic rotation inference. Positive values = clockwise rotation, negative
  #   values = counter-clockwise, 0 = force no rotation, +nil+ = use Eyes' automatic rotation inference.
  # +scale_ratio+:: +Float+|+nil+ The ratio by which to scale the screenshots received from the driver. Set this to
  #   override Eyes' automatic scaling inference. Values must be >=0 or +nil+. 1 = Don't scale, +nil+ = use Eyes'
  #   automatic scaling inference.
  # +force_fullpage_screenshot+:: +boolean+ Whether or not to force fullpage screenshot taking, if the browser doesn't
  #                               support it explicitly.
  # +hide_scrollbars+:: +boolean+ Whether or not hide scrollbars.
  # +use_css_transition+:: +boolean+ Whether or not to perform CSS transition.
  # +wait_before_screenshot+:: +Integer+ The number of milliseconds to wait before each screenshot. Use -1 to reset to
  #                            the default value.
  # +debug_screenshot+:: +boolean+ If true saves every taken screenshot in current folder. File name has following
  #                      format: +TAG_YYYY_MM_DD_HH_MI__N.png+, where +TAG+ - the tag specified for the test,
  #                      +YYYY_MM_DD_HH_MI+ - date && time, +N+ - screenshot number (makes sense only when
  #                      +force_fullpage_screenshot+ is true). Default value is false

  attr_reader :app_name, :test_name, :is_open, :viewport_size, :driver, :passed_driver
  attr_accessor :match_timeout, :batch, :host_os, :host_app, :branch_name, :parent_branch_name, :user_inputs,
    :save_new_tests, :save_failed_tests, :is_disabled, :server_url, :agent_id, :failure_reports,
    :match_level, :baseline_name, :rotation, :force_fullpage_screenshot, :hide_scrollbars,
    :use_css_transition, :scale_ratio, :wait_before_screenshots, :debug_screenshot

  def_delegators 'Applitools::EyesLogger', :log_handler, :log_handler=
  def_delegators 'Applitools::Base::ServerConnector', :api_key, :api_key=, :server_url, :server_url=, :set_proxy

  def wait_before_screenshots=(ms)
    @wait_before_screenshots = ms > 0 ? (ms / 1000.0) : DEFAULT_WAIT_BEFORE_SCREENSHOTS
  end

  def full_agent_id
    @full_agent_id ||= agent_id.nil? ? BASE_AGENT_ID : "#{agent_id} [#{BASE_AGENT_ID}]"
  end

  def title
    unless @dont_get_title
      begin
        return driver.title
      rescue
        @dont_get_title = true
      end
    end

    ''
  end

  def initialize(options = {})
    @is_disabled = false
    @debug_screenshot = options[:debug_screenshot].nil? ? false : true
    return if disabled?

    @api_key = nil
    @user_inputs = []

    Applitools::Base::ServerConnector.server_url = options[:server_url]

    @match_timeout = DEFAULT_MATCH_TIMEOUT
    @match_level = Applitools::Eyes::MATCH_LEVEL[:exact]
    @failure_reports = Applitools::Eyes::FAILURE_REPORTS[:on_close]
    @save_new_tests = true
    @save_failed_tests = false
    @dont_get_title = false
    @force_fullpage_screenshot = false
    @hide_scrollbars = false
    @use_css_transition = false
    @wait_before_screenshots = DEFAULT_WAIT_BEFORE_SCREENSHOTS
  end

  def open(options = {})
    @passed_driver = @driver = get_driver(options.merge(debug_screenshot: debug_screenshot))
    return driver if disabled?

    if api_key.nil?
      raise Applitools::EyesError.new('API key not set! Log in to https://applitools.com to obtain your API Key and '\
        "use 'api_key' to set it.")
    end

    if driver.respond_to? :driver_for_eyes
      @driver = driver.driver_for_eyes self
    else
      unless driver.is_a?(Applitools::Selenium::Driver)
        is_mobile_device = driver.respond_to?(:capabilities) && driver.capabilities['platformName']

        @driver =
          case driver
          when Selenium::WebDriver
            Applitools::Selenium::Driver.new(self, driver: driver, is_mobile_device: is_mobile_device)
          when Capybara::Poltergeist::Driver # driver for PhantomJS
            Applitools::Poltergeist::Driver.new(self, driver: driver, is_mobile_device: is_mobile_device)
          else
            Applitools::EyesLogger.warn("Unrecognized driver type: (#{driver.class.name})!")
            Applitools::Selenium::Driver.new(self, driver: driver, is_mobile_device: is_mobile_device)
          end

      end
    end

    @driver.wait_before_screenshots = wait_before_screenshots

    if open?
      abort_if_not_closed
      msg = 'a test is already running'
      Applitools::EyesLogger.warn(msg)

      raise Applitools::EyesError.new(msg)
    end

    @user_inputs = []
    @app_name = options.fetch(:app_name)
    if @app_name.nil? || @app_name.empty?
      raise Applitools::EyesError.new('App name must be a non empty string.')
    end
    @test_name = options.fetch(:test_name)
    if @test_name.nil? || @test_name.empty?
      raise Applitools::EyesError.new('Test name must be a non empty string.')
    end
    @viewport_size = options.fetch(:viewport_size, nil)

    @is_open = true

    driver
  end

  def open?
    is_open
  end

  def clear_user_inputs
    user_inputs.clear
  end

  def check_region(how, what, tag = nil, specific_timeout = -1)
    Applitools::EyesLogger.debug 'check_region called'
    return if disabled?

    # We have to start the session if it's not started, since we want the viewport size to be set before getting the
    # element's position and size
    raise Applitools::EyesError.new('Eyes not open') unless open?

    unless @session
      Applitools::EyesLogger.debug 'Starting session...'
      start_session
      Applitools::EyesLogger.debug 'Done! Creating match window task...'
      @match_window_task = Applitools::Selenium::MatchWindowTask.new(self, @session, driver, match_timeout)
      Applitools::EyesLogger.debug 'Done!'
    end

    original_overflow = driver.hide_scrollbars if hide_scrollbars
    begin
      if how == :element
        Applitools::EyesLogger.debug 'Element given as an argument...'
        raise Applitools::EyesError.new('Element does not exist') if what.nil?
        element_to_check = what
      elsif how == :region && what.is_a?(Applitools::Base::Region)
        return check_region_(what, tag, specific_timeout)
      else
        Applitools::EyesLogger.debug 'Finding element...'
        element_to_check = driver.find_element(how, what)
      end

      Applitools::EyesLogger.debug 'Done! Getting element location...'
      location = element_to_check.location
      Applitools::EyesLogger.debug 'Done! Getting element size...'
      size = element_to_check.size
      raise Applitools::EyesError.new("Invalid region size: #{size}") if size.width <= 0 || size.height <= 0
      Applitools::EyesLogger.debug 'Done! Creating region...'
      region = Applitools::Base::Region.new(location.x, location.y, size.width, size.height)
      Applitools::EyesLogger.debug "Done! Checking region... #{region}"
      check_region_(region, tag, specific_timeout)
      Applitools::EyesLogger.debug 'Done!'
    ensure
      driver.set_overflow(original_overflow) if hide_scrollbars
    end
  end

  def check_window(tag = nil, specific_timeout = -1)
    original_overflow = driver.hide_scrollbars if hide_scrollbars
    begin
      check_region_(Applitools::Base::Region::EMPTY, tag, specific_timeout)
    ensure
      driver.set_overflow(original_overflow) if hide_scrollbars
    end
  end

  def close(raise_ex = true)
    return if disabled?
    @is_open = false
    passed_driver.use_native_browser if passed_driver.respond_to? :use_native_browser

    # If there's no running session, the test was never started (never reached check_window).
    unless @session
      Applitools::EyesLogger.debug 'Server session was not started'
      Applitools::EyesLogger.info '--- Empty test ended.'

      return Applitools::Base::TestResults.new
    end

    session_results_url = @session.url
    new_session = @session.new_session?
    Applitools::EyesLogger.debug 'Ending server session...'
    save = (new_session && save_new_tests) || (!new_session && save_failed_tests)
    results = Applitools::Base::ServerConnector.stop_session(@session, false, save)
    results.is_new = new_session
    results.url = session_results_url
    Applitools::EyesLogger.debug "Results: #{results}"

    @session = nil

    if new_session
      instructions = "Please approve the new baseline at #{session_results_url}"
      Applitools::EyesLogger.info "--- New test ended. #{instructions}"

      if raise_ex
        message = "'#{@session_start_info.scenario_id_or_name}' of '#{@session_start_info.app_id_or_name}'. "\
          "#{instructions}"

        raise Applitools::NewTestError.new(message, results)
      end

      return results
    end

    unless results.passed?
      # Test failed
      Applitools::EyesLogger.info "--- Failed test ended. See details at #{session_results_url}"

      if raise_ex
        message = "'#{@session_start_info.scenario_id_or_name}' of '#{@session_start_info.app_id_or_name}'. see "\
          "details at #{session_results_url}"

        raise Applitools::TestFailedError.new(message, results)
      end

      return results
    end

    # Test passed
    Applitools::EyesLogger.info "--- Test passed. See details at #{session_results_url}"

    results
  end

  ## Use this method to perform seamless testing with selenium through eyes driver.
  ## Using Selenium methods inside the 'test' block will send the messages to Selenium
  ## after creating the Eyes triggers for them.
  ##
  ## Example:
  #    eyes.test(app_name: 'my app1', test_name: 'my test') do |d|
  #      get "http://www.google.com"
  #      check_window("initial")
  #    end
  # noinspection RubyUnusedLocalVariable
  def test(options = {}, &_block)
    open(options)
    yield(driver)
    close
  ensure
    abort_if_not_closed
  end

  def abort_if_not_closed
    return if disabled?

    @is_open = false
    passed_driver.use_native_browser if passed_driver.respond_to? :use_native_browser

    return unless @session

    begin
      Applitools::Base::ServerConnector.stop_session(@session, true, false)
    rescue => e
      Applitools::EyesLogger.error "Failed to abort server session: #{e.message}!"
    ensure
      @session = nil
    end
  end

  private

  def disabled?
    is_disabled
  end

  def get_driver(options)
    # TODO: remove the "browser" related block when possible. It's for backward compatibility.
    if options.key?(:browser)
      Applitools::EyesLogger.warn('"browser" key is deprecated, please use "driver" instead.')

      return options[:browser]
    end

    options.fetch(:driver, nil)
  end

  def inferred_environment
    user_agent = driver.user_agent
    "useragent:#{user_agent}" if user_agent
  end

  # Application environment is the environment (e.g., the host OS) which runs the application under test.
  #
  # Returns:
  # +Applitools::Base::Environment+ The application environment.
  def app_environment
    os = host_os
    if os.nil?
      Applitools::EyesLogger.info 'No OS set, checking for mobile OS...'
      if driver.mobile_device?
        platform_name = nil
        Applitools::EyesLogger.info 'Mobile device detected! Checking device type..'
        if driver.android?
          Applitools::EyesLogger.info 'Android detected.'
          platform_name = ANDROID
        elsif driver.ios?
          Applitools::EyesLogger.info 'iOS detected.'
          platform_name = IOS
        else
          Applitools::EyesLogger.warn 'Unknown device type.'
        end
        # We only set the OS if we identified the device type.
        unless platform_name.nil?
          platform_version = driver.platform_version
          if platform_version.nil?
            os = platform_name
          else
            # Notice that Ruby's +split+ function's +limit+ is the number of elements, whereas in Python it is the
            # maximum splits performed (which is why they are set differently).
            major_version = platform_version.split('.', 2)[0]
            os = "#{platform_name} #{major_version}"
          end
          Applitools::EyesLogger.info "Setting OS: #{os}"
        end
      else
        Applitools::EyesLogger.info 'No mobile OS detected.'
      end
    end

    # Create and return the environment object.
    Applitools::Base::Environment.new(os, host_app, viewport_size, inferred_environment)
  end

  def start_session
    assign_viewport_size
    @batch ||= Applitools::Base::BatchInfo.new
    app_env = app_environment

    @session_start_info = Applitools::Base::StartInfo.new(full_agent_id, app_name, test_name, batch, baseline_name,
      app_env, match_level, nil, branch_name, parent_branch_name)
    @session = Applitools::Base::ServerConnector.start_session(@session_start_info)
    @should_match_window_run_once_on_timeout = @session.new_session?
  end

  def viewport_size?
    viewport_size
  end

  def assign_viewport_size
    if viewport_size?
      @viewport_size = Applitools::Selenium::ViewportSize.new(driver, viewport_size)
      @viewport_size.set
    else
      @viewport_size = Applitools::Selenium::ViewportSize.new(driver)
      @viewport_size.extract_viewport_from_browser!
    end
  end

  def check_region_(region, tag = nil, specific_timeout = -1)
    return if disabled?
    Applitools::EyesLogger.info "check_region_('#{tag}', #{specific_timeout})"
    raise Applitools::EyesError.new('region cannot be nil!') if region.nil?
    raise Applitools::EyesError.new('Eyes not open') unless open?

    unless @session
      Applitools::EyesLogger.debug 'Starting session...'
      start_session
      Applitools::EyesLogger.debug 'Done! Creating match window task...'
      @match_window_task = Applitools::Selenium::MatchWindowTask.new(self, @session, driver, match_timeout)
      Applitools::EyesLogger.debug 'Done!'
    end

    Applitools::EyesLogger.debug 'Starting match task...'
    as_expected = @match_window_task.match_window(region, specific_timeout, tag, rotation,
      @should_match_window_run_once_on_timeout)
    Applitools::EyesLogger.debug 'Match window done!'
    return if as_expected

    @should_match_window_run_once_on_timeout = true
    return if @session.new_session?

    Applitools::EyesLogger.info %(mismatch #{tag ? '' : "(#{tag})"})
    return unless failure_reports.to_i == Applitools::Eyes::FAILURE_REPORTS[:immediate]

    raise Applitools::TestFailedError.new("Mismatch found in '#{@session_start_info.scenario_id_or_name}' "\
      "of '#{@session_start_info.app_id_or_name}'")
  end
end
