class Applitools::Eyes

  DEFAULT_MATCH_TIMEOUT = 2.0  # Seconds
  BASE_AGENT_ID = 'eyes.selenium.ruby/' + Applitools::VERSION
  DEFAULT_EYES_SERVER = 'https://eyessdk.applitools.com'

  private
  attr_reader :agent_connector, :full_agent_id
  attr_accessor :session, :session_start_info, :match_window_task, :should_match_window_run_once_on_timeout,
                :dont_get_title

  public
  #
  # Attributes:
  #
  # +app_name+:: +String+ The application name which was provided as an argument to +open+.
  # +test_name+:: +String+ The test name which was provided as an argument to +open+.
  # +is_open+:: +boolean+ Is there an open session.
  # +viewport_size+:: +Hash+ The viewport size which was provided as an argument to +open+. Should include +width+
  #                    and +height+.
  # +driver+:: +Applitools::Driver+ The driver instance wrapping the driver which was provided as an argument to +open+.
  # +api_key+:: +String+ The user's API key.
  # +match_timeout+:: +Float+ The default timeout for check_XXXX operations. (Seconds)
  # +batch+:: +BatchInfo+ The current tests grouping, if any.
  # +host_os+:: +String+ A string identifying the OS running the AUT. Set this if you wish to override Eyes' automatic
  #             inference.
  # +host_app+:: +String+ A string identifying the container application running the AUT (e.g., Firefox). Set this if
  #               you wish to override Eyes' automatic inference.
  # +branch_name+:: +String+ If set, names the branch in which the test should run.
  # +parent_branch_name+:: +String+ If set, names the parent branch of the branch in which the test should run.
  # +user_inputs+:: +Applitools::MouseTrigger+/+Applitools::KeyboardTrigger+ Mouse/Keyboard events which happened after
  #                 the last visual validation.
  # +save_new_tests+:: +boolean+ Whether or not new tests should be automatically accepted as baseline.
  # +save_failed_tests+:: +boolean+ Whether or not failed tests should be automatically accepted as baseline.
  # +match_level+:: +String+ The default match level for the entire session. See +Applitools::MatchLevel+.
  # +baseline_name+:: +String+ A string identifying the baseline which the test will be compared against. Set this if
  #                   you wish to override Eyes' automatic baseline inference.
  # +is_disabled+:: +boolean+ Set to +true+ if you wish to disable Eyes without deleting code (Eyes' methods act as a
  #                 mock, and will do nothing).
  # +server_url+:: +String+ The Eyes' server. Set this if you wish to override the default Eyes server URL.
  # +agent_id+:: +String+ An optional string identifying the current library using the SDK.
  # +log_handler+:: +Logger+ The logger to which Eyes will send info/debug messages.
  # +failure_reports+:: +String+ Whether the current test will report mismatches immediately or when it is finished.
  #                     See +Applitools::FailureReports+.
  # +rotation+:: +Integer+|+nil+ The degrees by which to rotate the screenshots received from the driver. Set this to
  #               override Eyes' automatic rotation inference. Positive values = clockwise rotation,
  #               negative values = counter-clockwise, 0 = force no rotation, +nil+ = use Eyes' automatic rotation
  #               inference.
  #
  attr_reader :app_name, :test_name, :is_open, :viewport_size, :driver
  attr_accessor :match_timeout, :batch, :host_os, :host_app, :branch_name, :parent_branch_name, :user_inputs,
                :save_new_tests, :save_failed_tests, :api_key, :is_disabled, :server_url, :agent_id, :log_handler,
                :failure_reports, :match_level, :baseline_name, :rotation

  def log_handler
    EyesLogger.log_handler
  end

  def log_handler=(handler)
    EyesLogger.log_handler = handler
  end

  def api_key
    @agent_connector.api_key
  end

  def api_key=(api_key)
    @agent_connector.api_key = api_key
  end

  def server_url
    @agent_connector.server_url
  end

  def server_url=(server_url)
    if server_url.nil?
      @agent_connector.server_url = DEFAULT_EYES_SERVER
    else
      @agent_connector.server_url = server_url
    end
  end

  def full_agent_id
    if agent_id.nil?
      return BASE_AGENT_ID
    end
    "#{agent_id} [#{BASE_AGENT_ID}]"
  end

  def title
    unless dont_get_title
      begin
       return driver.title
      rescue
        self.dont_get_title = true
      end
    end
    ''
  end

  def initialize(params={})

    @is_disabled = false

    return if disabled?

    @api_key = nil
    @user_inputs = []
    server_url = params.fetch(:server_url, DEFAULT_EYES_SERVER)
    @agent_connector = Applitools::AgentConnector.new(server_url)
    @match_timeout = DEFAULT_MATCH_TIMEOUT
    @match_level = Applitools::MatchLevel::EXACT
    @failure_reports = Applitools::FailureReports::ON_CLOSE
    @save_new_tests = true
    @save_failed_tests = false
    @dont_get_title = false
  end

  def open(params={})
    @driver = get_driver(params)
    return driver if disabled?

    if api_key.nil?
      #noinspection RubyQuotedStringsInspection
      raise Applitools::EyesError.new(
                "API key not set! Log in to https://applitools.com to obtain your API Key and use 'api_key' to set it.")
    end

    if driver.is_a?(Selenium::WebDriver::Driver)
      @driver = Applitools::Driver.new(self, {driver: driver})
    elsif driver.is_a?(Appium::Driver)
      @driver = Applitools::Driver.new(self, {driver: driver.driver, is_mobile_device: true})
    else
      unless driver.is_a?(Applitools::Driver)
        raise Applitools::EyesError.new("Driver is not a Selenium::WebDriver::Driver (#{driver.class.name})")
      end
    end

    if open?
      abort_if_not_closed
      msg = 'a test is already running'
      EyesLogger.info(msg) and raise Applitools::EyesError.new(msg)
    end

    @user_inputs = []
    @app_name = params.fetch(:app_name)
    @test_name = params.fetch(:test_name)
    @viewport_size = params.fetch(:viewport_size, nil)

    @is_open = true
    driver
  end

  def open?
    is_open
  end

  def clear_user_inputs
    user_inputs.clear
  end

  def check_region(how, what, tag=nil, specific_timeout=-1)
    EyesLogger.debug 'check_region called'
    return if disabled?
    # We have to start the session if it's not started, since we want the viewport size to be set before getting the
    # element's position and size
    raise Applitools::EyesError.new('Eyes not open') if !open?
    unless session
      EyesLogger.debug 'Starting session...'
      start_session
      EyesLogger.debug 'Done! Creating match window task...'
      self.match_window_task = Applitools::MatchWindowTask.new(self, agent_connector, session, driver, match_timeout)
      EyesLogger.debug 'Done!'
    end

    EyesLogger.debug 'Finding element...'
    element_to_check = driver.find_element(how, what)
    EyesLogger.debug 'Done! Getting element location...'
    location = element_to_check.location
    EyesLogger.debug 'Done! Getting element size...'
    size = element_to_check.size
    EyesLogger.debug 'Done! Creating region...'
    region = Applitools::Region.new(location.x, location.y, size.width, size.height)
    EyesLogger.debug 'Done! Checking region...'
    check_region_(region, tag, specific_timeout)
    EyesLogger.debug 'Done!'
  end

  def check_window(tag=nil, specific_timeout=-1)
    check_region_(Applitools::Region::EMPTY, tag, specific_timeout)
  end

  def close(raise_ex=true)
    return if disabled?
    @is_open = false

    # if there's no running session, the test was never started (never reached checkWindow)
    if !session
      EyesLogger.debug 'close(): Server session was not started'
      EyesLogger.info 'close(): --- Empty test ended.'
      return Applitools::TestResults.new
    end

    session_results_url = session.url
    new_session = session.new_session?
    EyesLogger.debug "close(): Ending server session..."
    save = (new_session && save_new_tests) || (!new_session && save_failed_tests)
    results = agent_connector.stop_session(session, false, save)
    results.is_new = new_session
    results.url = session_results_url
    EyesLogger.debug "close(): #{results}"

    self.session = nil

    if new_session
      instructions = "Please approve the new baseline at #{session_results_url}"
      EyesLogger.info "--- New test ended.  #{instructions}"
      if raise_ex
        message = "'#{session_start_info.scenario_id_or_name}' of"\
                " '#{session_start_info.app_id_or_name}'. #{instructions}"
        raise Applitools::NewTestError.new(message, results)
      end
      return results
    end

    if !results.is_passed
      # Test failed
      EyesLogger.info "--- Failed test ended. See details at #{session_results_url}"
      if raise_ex
        message = "'#{session_start_info.scenario_id_or_name}' of"\
                " '#{session_start_info.app_id_or_name}'. see details at #{session_results_url}"
        raise Applitools::TestFailedError.new(message, results)
      end
      return results
    end

    # Test passed
    EyesLogger.info "--- Test passed. See details at #{session_results_url}"
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
  #noinspection RubyUnusedLocalVariable
  def test(params={}, &block)
    begin
      open(params)
      yield(driver)
      close
    ensure
      abort_if_not_closed
    end
  end


  def abort_if_not_closed
    return if disabled?
    @is_open = false
    if session
      begin
        agent_connector.stop_session(session, true, false)
      rescue Applitools::EyesError => e
        EyesLogger.info "Failed to abort server session -> #{e.message} "
      ensure
        self.session = nil
      end
    end
  end

  private

    def disabled? 
      is_disabled
    end

    def get_driver(params)
      # TODO remove the "browser" related block when possible. It's for backward compatibility.
      if params.has_key?(:browser)
        EyesLogger.info('"browser" key is deprecated, please use "driver" instead.')
        return params[:browser]
      end
      params.fetch(:driver, nil)
    end

    def inferred_environment
      user_agent = driver.user_agent
      if user_agent
        "useragent:#{user_agent}"
      else
        nil
      end
    end

    # Application environment is the environment (e.g., the host OS) which runs the application under test.
    #
    # Returns:
    # +Applitools::Environment+ The application environment.
    def app_environment
      os = host_os
      if os.nil?
        EyesLogger.info 'No OS set, checking for mobile OS...'
        if driver.mobile_device?
          platform_name = nil
          EyesLogger.info 'Mobile device detected! Checking device type..'
          if driver.android?
            EyesLogger.info 'Android detected.'
            platform_name = 'Android'
          elsif driver.ios?
            EyesLogger.info 'iOS detected.'
            platform_name = 'iOS'
          else
            EyesLogger.info 'Unknown device type.'
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
            EyesLogger.info "Setting OS: #{os}"
          end
        else
          EyesLogger.info 'No mobile OS detected.'
        end
      end
      # Create and return the environment object.
      Applitools::Environment.new(os, host_app, viewport_size, inferred_environment)
    end

    def start_session
      assign_viewport_size
      self.batch ||= Applitools::BatchInfo.new
      app_env = app_environment
      self.session_start_info = Applitools::StartInfo.new(
          full_agent_id, app_name, test_name, batch, baseline_name, app_env, match_level, nil, branch_name, parent_branch_name
      )
      self.session = agent_connector.start_session(session_start_info)
      self.should_match_window_run_once_on_timeout = session.new_session?
    end

    def viewport_size?
      viewport_size
    end

    def assign_viewport_size
      if viewport_size?
        @viewport_size = Applitools::ViewportSize.new(driver, viewport_size)
	      viewport_size.set
      else
        @viewport_size =  Applitools::ViewportSize.new(driver).extract_viewport_from_browser!
      end
    end

  def check_region_(region, tag=nil, specific_timeout=-1)
    return if disabled?
    EyesLogger.info "check_region_('#{tag}', #{specific_timeout})"
    raise Applitools::EyesError.new('region cannot be nil!') if region.nil?
    raise Applitools::EyesError.new('Eyes not open') if !open?

    unless session
      EyesLogger.debug 'Starting session...'
      start_session
      EyesLogger.debug 'Done! Creating match window task...'
      self.match_window_task = Applitools::MatchWindowTask.new(self, agent_connector, session, driver, match_timeout)
      EyesLogger.debug 'Done!'
    end

    EyesLogger.debug 'Starting match task...'
    as_expected = match_window_task.match_window(region, specific_timeout, tag, rotation, should_match_window_run_once_on_timeout)
    EyesLogger.debug 'Match window done!'
    unless as_expected
      self.should_match_window_run_once_on_timeout = true
      unless session.new_session?
        EyesLogger.info %( mismatch #{ tag ? '' : "(#{tag})" } )
        if failure_reports.to_i == Applitools::FailureReports::IMMEDIATE
          raise Applitools::TestFailedError.new("Mismatch found in '#{session_start_info.scenario_id_or_name}'"\
                                                " of '#{session_start_info.app_id_or_name}'")
        end
      end
    end
  end
end
