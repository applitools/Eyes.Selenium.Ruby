class Applitools::ViewportSize

  GET_VIEWPORT_HEIGHT_JAVASCRIPT_FOR_NORMAL_BROWSER = "return window.innerHeight"
  GET_VIEWPORT_WIDTH_JAVASCRIPT_FOR_NORMAL_BROWSER  = "return window.innerWidth"

  DOCUMENT_CLEAR_SCROLL_BARS_JAVASCRIPT = "var doc = document.documentElement;" +
                                          "var previousOverflow = doc.style.overflow;"
  DOCUMENT_RESET_SCROLL_BARS_JAVASCRIPT = "doc.style.overflow = previousOverflow;"
  DOCUMENT_RETURN_JAVASCRIPT            = "return __applitools_result;"

  GET_VIEWPORT_WIDTH_JAVASCRIPT_FOR_BAD_BROWSERS = 
                  DOCUMENT_CLEAR_SCROLL_BARS_JAVASCRIPT        +
                  "var __applitools_result = doc.clientWidth;" +
                  DOCUMENT_RESET_SCROLL_BARS_JAVASCRIPT        +
                  DOCUMENT_RETURN_JAVASCRIPT

  GET_VIEWPORT_HEIGHT_JAVASCRIPT_FOR_BAD_BROWSERS = 
                  DOCUMENT_CLEAR_SCROLL_BARS_JAVASCRIPT         +
                  "var __applitools_result = doc.clientHeight;" +
                  DOCUMENT_RESET_SCROLL_BARS_JAVASCRIPT         +
                  DOCUMENT_RETURN_JAVASCRIPT

  attr_reader :driver
  attr_accessor :dimension
  def initialize(driver, dimension=nil)
    @driver = driver
    @dimension = dimension
  end

  def extract_viewport_width
     begin
       return driver.execute_script(GET_VIEWPORT_WIDTH_JAVASCRIPT_FOR_NORMAL_BROWSER)
     rescue => e 
       EyesLogger.info "getViewportSize(): Browser does not support innerWidth (#{e.message})"
     end

    driver.execute_script(GET_VIEWPORT_WIDTH_JAVASCRIPT_FOR_BAD_BROWSERS)
  end

  def extract_viewport_height
     begin
       return driver.execute_script(GET_VIEWPORT_HEIGHT_JAVASCRIPT_FOR_NORMAL_BROWSER)
     rescue  => e 
       EyesLogger.info "getViewportSize(): Browser does not support innerHeight (#{e.message})"
     end

    driver.execute_script(GET_VIEWPORT_HEIGHT_JAVASCRIPT_FOR_BAD_BROWSERS)
  end

  def extract_viewport_from_browser!
    self.dimension = extract_viewport_from_browser
  end

  def extract_viewport_from_browser
    width  = extract_viewport_width 
    height = extract_viewport_height
    Applitools::Dimension.new(width,height)
  rescue => e
    EyesLogger.info "getViewportSize(): only window size is available (#{e.message})"
    width, height = *browser_size.values
    Applitools::Dimension.new(width,height)
  end
  alias_method :viewport_size, :extract_viewport_from_browser

  def set
    if dimension.is_a?(Hash) && dimension.has_key?(:width) && dimension.has_key?(:height)
      # If dimension is hash of width/height, we convert it to a struct with width/height properties.
      self.dimension = Struct.new(:width, :height).new(dimension[:width], dimension[:height])
    elsif !dimension.respond_to?(:width) || !dimension.respond_to?(:height)
      raise ArgumentError, "expected #{dimension.inspect}:#{dimension.class}" +
                           " to respond to #width and #height, or be a hash with these keys"
    end
    self.browser_size = dimension
    verify_size(:browser_size)
    cur_viewport_size = extract_viewport_from_browser
    self.browser_size = Applitools::Dimension.new(
                          (2 * browser_size.width) - cur_viewport_size.width,
                          (2 * browser_size.height) - cur_viewport_size.height
                        )
    verify_size(:viewport_size)
  end

  def verify_size(to_verify, sleep_time=1, retries=3)
    cur_size = nil
    retries.times do
      sleep(sleep_time) 
      cur_size = send(to_verify)
      return if cur_size.values == dimension.values
    end
    EyesLogger.info(err_msg = "Failed setting #{to_verify} to #{dimension.values} (current size: #{cur_size.values})")
    raise Applitools::TestFailedError.new(err_msg)
  end

  def browser_size
    driver.manage.window.size
  end

  def browser_size=(other)
    self.driver.manage.window.size = other
  end

  def to_hash
    Hash[dimension.each_pair.to_a]
  end
end
