require 'oily_png'
require 'base64'

class Applitools::MatchWindowTask

  private
  MATCH_INTERVAL = 0.5
  AppOutput = Struct.new(:title, :screenshot64)

  attr_reader :eyes, :agent_connector, :session, :driver, :default_retry_timeout, :last_checked_window ,:last_screenshot_bounds

  public
  #noinspection RubyParameterNamingConvention
  def initialize(eyes, agent_connector, session, driver, default_retry_timeout)
    @eyes = eyes
    @agent_connector = agent_connector
    @session = session
    @driver = driver
    @default_retry_timeout = default_retry_timeout
    @last_checked_window = nil # +ChunkyPNG::Canvas+
    @last_screenshot_bounds = Applitools::Region::EMPTY # +Applitools::Region+
    @current_screenshot = nil # +ChunkyPNG::Canvas+
  end

  def match_window(region, retry_timeout, tag,run_once_after_wait=false)
    if retry_timeout < 0
      retry_timeout = default_retry_timeout
    end
    EyesLogger.debug "Retry timeout set to: #{retry_timeout}"
    start = Time.now
    res = if retry_timeout.zero?
            run(region, tag)
          elsif run_once_after_wait
            run(region, tag, retry_timeout)
          else
            run_with_intervals(region, tag, retry_timeout)
          end
    elapsed_time = Time.now - start
    EyesLogger.debug "match_window(): Completed in #{format('%.2f', elapsed_time)} seconds"
    @last_checked_window = @current_screenshot
    @last_screenshot_bounds = region.empty? ? Applitools::Region.new(0, 0, last_checked_window.width, last_checked_window.height) : region
    #noinspection RubyUnnecessaryReturnStatement
    driver.eyes.clear_user_inputs and return res
  end

  def run(region, tag, wait_before_run=nil)
    EyesLogger.debug 'Trying matching once...'
    if wait_before_run
      EyesLogger.debug 'waiting before run...'
      sleep(wait_before_run)
      EyesLogger.debug 'waiting done!'
    end
    match(region, tag)
  end

  def run_with_intervals(region, tag, retry_timeout)
    # We intentionally take the first screenshot before starting the timer, to allow the page
    # just a tad more time to stabilize.
    EyesLogger.debug 'Matching with intervals...'
    data = prep_match_data(region, tag, true)
    start = Time.now
    as_expected = agent_connector.match_window(session, data)
    EyesLogger.debug "First call result: #{as_expected}"
    return true if as_expected
    EyesLogger.debug "Not as expected, performing retry (total timeout #{retry_timeout})"
    match_retry = Time.now - start
    while match_retry < retry_timeout
      EyesLogger.debug 'Waiting before match...'
      sleep(MATCH_INTERVAL)
      EyesLogger.debug 'Done! Matching...'
      return true if match(region, tag, true)
      match_retry = Time.now - start
      EyesLogger.debug "Elapsed time: #{match_retry}"
    end
    ## lets try one more time if we still don't have a match
    EyesLogger.debug 'Last attempt to match...'
    as_expected = match(region, tag)
    EyesLogger.debug "Match result: #{as_expected}"
    as_expected
  end

  private

    def get_clipped_region(region, image)
      left, top = [region.left, 0].max, [region.top, 0].max
      max_width = image.width - left
      max_height = image.height - top
      width, height = [region.width, max_width].min, [region.height, max_height].min
      Applitools::Region.new(left, top, width, height)
    end

    def prep_match_data(region, tag, ignore_mismatch)
      EyesLogger.debug 'Preparing match data...'
      title = eyes.title
      EyesLogger.debug 'Getting screenshot...'
      screenshot64 = driver.screenshot_as(:base64)
      # We need a reference to the raw bytes of the PNG, which is why we didn't
      # use +Applitools::Utils::ImageUtils.image_from_base64+.
      EyesLogger.debug 'Done! Decoding base64...'
      current_screenshot_encoded = Base64.decode64(screenshot64)
      EyesLogger.debug 'Done! Creating image object from PNG...'
      @current_screenshot = ChunkyPNG::Image.from_blob(current_screenshot_encoded)
      EyesLogger.debug 'Done!'
      # If a region was defined, we refer to the sub-image defined by the region.
      unless region.empty?
        EyesLogger.debug 'Calculating clipped region...'
        # If the region is out of bounds, clip it
        clipped_region = get_clipped_region(region, @current_screenshot)
        raise Applitools::EyesError.new("Region is outside the viewport: #{region}") if clipped_region.empty?
        EyesLogger.debug 'Done! Cropping region...'
        @current_screenshot.crop!(clipped_region.left, clipped_region.top, clipped_region.width, clipped_region.height)
        EyesLogger.debug 'Done! Creating cropped image object...'
        current_screenshot_encoded = @current_screenshot.to_blob.force_encoding('BINARY')
        EyesLogger.debug 'Done!'
      end
      EyesLogger.debug 'Compressing screenshot...'
      compressed_screenshot = Applitools::Utils::ImageDeltaCompressor.compress_by_raw_blocks(@current_screenshot,
                                                                                  current_screenshot_encoded,
                                                                                  last_checked_window)
      EyesLogger.debug 'Done! Creating AppOuptut...'
      app_output = AppOutput.new(title, nil)
      user_inputs = []
      EyesLogger.debug 'Handling user inputs...'
      if !last_checked_window.nil?
        driver.eyes.user_inputs.each do |trigger|
          EyesLogger.debug 'Handling trigger...'
          if trigger.is_a?(Applitools::MouseTrigger)
            updated_trigger = nil
            trigger_left = trigger.control.left + trigger.location.x
            trigger_top = trigger.control.top + trigger.location.y
            if last_screenshot_bounds.contains?(trigger_left, trigger_top)
              trigger.control.intersect(last_screenshot_bounds)
              if trigger.control.empty?
                trigger_left = trigger_left - last_screenshot_bounds.left
                trigger_top = trigger_top -last_screenshot_bounds.top
                updated_trigger = Applitools::MouseTrigger.new(trigger.mouse_action, trigger.control, Selenium::WebDriver::Point.new(trigger_left, trigger_top))
              else
                trigger_left = trigger_left - trigger.control.left
                trigger_top = trigger_top - trigger.control.top
                control_left = trigger.control.left - last_screenshot_bounds.left
                control_top = trigger.control.top - last_screenshot_bounds.top
                updated_control = Applitools::Region.new(control_left, control_top, trigger.control.width, trigger.control.height)
                updated_trigger = Applitools::MouseTrigger.new(trigger.mouse_action, updated_control, Selenium::WebDriver::Point.new(trigger_left, trigger_top))
              end
              EyesLogger.debug 'Done with trigger!'
              user_inputs << updated_trigger
            else
              EyesLogger.info "Trigger ignored: #{trigger} (out of bounds)"
            end
          elsif trigger.is_a?(Applitools::TextTrigger)
            unless trigger.control.empty? 
              trigger.control.intersect(last_screenshot_bounds)
              unless trigger.control.empty?
                control_left = trigger.control.left - last_screenshot_bounds.left
                control_top = trigger.control.top - last_screenshot_bounds.top
                updated_control = Applitools::Region.new(control_left, control_top, trigger.control.width, trigger.control.height)
                updated_trigger = Applitools::TextTrigger.new(trigger.text, updated_control)
                EyesLogger.debug 'Done with trigger!'
                user_inputs << updated_trigger
              else 
                EyesLogger.info "Trigger ignored: #{trigger} (control out of bounds)"
              end
            else
              EyesLogger.info "Trigger ignored: #{trigger} (out of bounds)"
            end
          else
            EyesLogger.info "Trigger ignored: #{trigger} (Unrecognized trigger)"
          end
        end
      else
        EyesLogger.info 'Triggers ignored: no previous window checked'
      end
      EyesLogger.debug 'Creating MatchWindowData object..'
      match_window_data_obj = Applitools::MatchWindowData.new(app_output, user_inputs, tag, ignore_mismatch, compressed_screenshot)
      EyesLogger.debug 'Done creating MatchWindowData object!'
      match_window_data_obj
    end

    def match(region, tag, ignore_mismatch=false)
      EyesLogger.debug 'Match called...'
      data = prep_match_data(region, tag, ignore_mismatch)
      match_result = agent_connector.match_window(session, data)
      EyesLogger.debug 'Match done!'
      match_result
    end
end
