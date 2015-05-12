require 'base64'

class Applitools::Selenium::MatchWindowTask

  private
  MATCH_INTERVAL = 0.5
  AppOutput = Struct.new(:title, :screenshot64)

  attr_reader :eyes, :session, :driver, :default_retry_timeout, :last_checked_window ,:last_screenshot_bounds

  public
  #noinspection RubyParameterNamingConvention
  def initialize(eyes, session, driver, default_retry_timeout)
    @eyes = eyes

    @session = session
    @driver = driver
    @default_retry_timeout = default_retry_timeout
    @last_checked_window = nil # +ChunkyPNG::Canvas+
    @last_screenshot_bounds = Applitools::Selenium::Region::EMPTY # +Applitools::Selenium::Region+
    @current_screenshot = nil # +ChunkyPNG::Canvas+
  end

  def match_window(region, retry_timeout, tag, rotation, run_once_after_wait=false)
    if retry_timeout < 0
      retry_timeout = default_retry_timeout
    end
    Applitools::EyesLogger.debug "Retry timeout set to: #{retry_timeout}"
    start = Time.now
    res = if retry_timeout.zero?
            run(region, tag, rotation)
          elsif run_once_after_wait
            run(region, tag, rotation, retry_timeout)
          else
            run_with_intervals(region, tag, rotation, retry_timeout)
          end
    elapsed_time = Time.now - start
    Applitools::EyesLogger.debug "match_window(): Completed in #{format('%.2f', elapsed_time)} seconds"
    @last_checked_window = @current_screenshot
    @last_screenshot_bounds = region.empty? ? Applitools::Selenium::Region.new(0, 0, last_checked_window.width, last_checked_window.height) : region
    #noinspection RubyUnnecessaryReturnStatement
    driver.eyes.clear_user_inputs and return res
  end

  def run(region, tag, rotation, wait_before_run=nil)
    Applitools::EyesLogger.debug 'Trying matching once...'
    if wait_before_run
      Applitools::EyesLogger.debug 'waiting before run...'
      sleep(wait_before_run)
      Applitools::EyesLogger.debug 'waiting done!'
    end
    match(region, tag, rotation)
  end

  def run_with_intervals(region, tag, rotation, retry_timeout)
    # We intentionally take the first screenshot before starting the timer, to allow the page
    # just a tad more time to stabilize.
    Applitools::EyesLogger.debug 'Matching with intervals...'
    data = prep_match_data(region, tag, rotation, true)
    start = Time.now
    as_expected = Applitools::Selenium::ServerConnector.match_window(session, data)
    Applitools::EyesLogger.debug "First call result: #{as_expected}"
    return true if as_expected
    Applitools::EyesLogger.debug "Not as expected, performing retry (total timeout #{retry_timeout})"
    match_retry = Time.now - start
    while match_retry < retry_timeout
      Applitools::EyesLogger.debug 'Waiting before match...'
      sleep(MATCH_INTERVAL)
      Applitools::EyesLogger.debug 'Done! Matching...'
      return true if match(region, tag, rotation, true)
      match_retry = Time.now - start
      Applitools::EyesLogger.debug "Elapsed time: #{match_retry}"
    end
    ## lets try one more time if we still don't have a match
    Applitools::EyesLogger.debug 'Last attempt to match...'
    as_expected = match(region, tag, rotation)
    Applitools::EyesLogger.debug "Match result: #{as_expected}"
    as_expected
  end

  private

    def get_clipped_region(region, image)
      left, top = [region.left, 0].max, [region.top, 0].max
      max_width = image.width - left
      max_height = image.height - top
      width, height = [region.width, max_width].min, [region.height, max_height].min
      Applitools::Selenium::Region.new(left, top, width, height)
    end

    def prep_match_data(region, tag, rotation, ignore_mismatch)
      Applitools::EyesLogger.debug 'Preparing match data...'
      title = eyes.title
      Applitools::EyesLogger.debug 'Getting screenshot...'
      current_screenshot_encoded = driver.screenshot_as(:png, rotation)
      Applitools::EyesLogger.debug 'Done! Creating image object from PNG...'
      @current_screenshot = ChunkyPNG::Image.from_blob(current_screenshot_encoded)
      Applitools::EyesLogger.debug 'Done!'
      # If a region was defined, we refer to the sub-image defined by the region.
      unless region.empty?
        Applitools::EyesLogger.debug 'Calculating clipped region...'
        # If the region is out of bounds, clip it
        clipped_region = get_clipped_region(region, @current_screenshot)
        raise Applitools::EyesError.new("Region is outside the viewport: #{region}") if clipped_region.empty?
        Applitools::EyesLogger.debug 'Done! Cropping region...'
        @current_screenshot.crop!(clipped_region.left, clipped_region.top, clipped_region.width, clipped_region.height)
        Applitools::EyesLogger.debug 'Done! Creating cropped image object...'
        current_screenshot_encoded = @current_screenshot.to_blob.force_encoding('BINARY')
        Applitools::EyesLogger.debug 'Done!'
      end
      Applitools::EyesLogger.debug 'Compressing screenshot...'
      compressed_screenshot = Applitools::Utils::ImageDeltaCompressor.compress_by_raw_blocks(@current_screenshot,
                                                                                  current_screenshot_encoded,
                                                                                  last_checked_window)
      Applitools::EyesLogger.debug 'Done! Creating AppOuptut...'
      app_output = AppOutput.new(title, nil)
      user_inputs = []
      Applitools::EyesLogger.debug 'Handling user inputs...'
      if !last_checked_window.nil?
        driver.eyes.user_inputs.each do |trigger|
          Applitools::EyesLogger.debug 'Handling trigger...'
          if trigger.is_a?(Applitools::Selenium::MouseTrigger)
            updated_trigger = nil
            trigger_left = trigger.control.left + trigger.location.x
            trigger_top = trigger.control.top + trigger.location.y
            if last_screenshot_bounds.contains?(trigger_left, trigger_top)
              trigger.control.intersect(last_screenshot_bounds)
              if trigger.control.empty?
                trigger_left -= - last_screenshot_bounds.left
                trigger_top = trigger_top - last_screenshot_bounds.top
                updated_trigger = Applitools::Selenium::MouseTrigger.new(trigger.mouse_action, trigger.control, Selenium::WebDriver::Point.new(trigger_left, trigger_top))
              else
                trigger_left = trigger_left - trigger.control.left
                trigger_top = trigger_top - trigger.control.top
                control_left = trigger.control.left - last_screenshot_bounds.left
                control_top = trigger.control.top - last_screenshot_bounds.top
                updated_control = Applitools::Selenium::Region.new(control_left, control_top, trigger.control.width, trigger.control.height)
                updated_trigger = Applitools::Selenium::MouseTrigger.new(trigger.mouse_action, updated_control, Selenium::WebDriver::Point.new(trigger_left, trigger_top))
              end
              Applitools::EyesLogger.debug 'Done with trigger!'
              user_inputs << updated_trigger
            else
              Applitools::EyesLogger.info "Trigger ignored: #{trigger} (out of bounds)"
            end
          elsif trigger.is_a?(Applitools::Selenium::TextTrigger)
            unless trigger.control.empty?
              trigger.control.intersect(last_screenshot_bounds)
              unless trigger.control.empty?
                control_left = trigger.control.left - last_screenshot_bounds.left
                control_top = trigger.control.top - last_screenshot_bounds.top
                updated_control = Applitools::Selenium::Region.new(control_left, control_top, trigger.control.width, trigger.control.height)
                updated_trigger = Applitools::Selenium::TextTrigger.new(trigger.text, updated_control)
                Applitools::EyesLogger.debug 'Done with trigger!'
                user_inputs << updated_trigger
              else
                Applitools::EyesLogger.info "Trigger ignored: #{trigger} (control out of bounds)"
              end
            else
              Applitools::EyesLogger.info "Trigger ignored: #{trigger} (out of bounds)"
            end
          else
            Applitools::EyesLogger.info "Trigger ignored: #{trigger} (Unrecognized trigger)"
          end
        end
      else
        Applitools::EyesLogger.info 'Triggers ignored: no previous window checked'
      end
      Applitools::EyesLogger.debug 'Creating MatchWindowData object..'
      match_window_data_obj = Applitools::Selenium::MatchWindowData.new(app_output, user_inputs, tag, ignore_mismatch, compressed_screenshot)
      Applitools::EyesLogger.debug 'Done creating MatchWindowData object!'
      match_window_data_obj
    end

    def match(region, tag, rotation, ignore_mismatch=false)
      Applitools::EyesLogger.debug 'Match called...'
      data = prep_match_data(region, tag, rotation, ignore_mismatch)
      match_result = Applitools::Selenium::ServerConnector.match_window(session, data)
      Applitools::EyesLogger.debug 'Match done!'
      match_result
    end
end
