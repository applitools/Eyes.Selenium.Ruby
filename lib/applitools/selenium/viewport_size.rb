class Applitools::Selenium::ViewportSize
  JS_GET_VIEWPORT_HEIGHT = <<-EOF
    var height = undefined;
    if (window.innerHeight) {
      height = window.innerHeight;
    }
    else if (document.documentElement && document.documentElement.clientHeight) {
      height = document.documentElement.clientHeight;
    } else {
      var b = document.getElementsByTagName("body")[0];
      if (b.clientHeight) {
        height = b.clientHeight;
      }
    }

    return height;
  EOF

  JS_GET_VIEWPORT_WIDTH  = <<-EOF
    var width = undefined;
    if (window.innerWidth) {
      width = window.innerWidth
    } else if (document.documentElement && document.documentElement.clientWidth) {
      width = document.documentElement.clientWidth;
    } else {
      var b = document.getElementsByTagName("body")[0];
      if (b.clientWidth) {
        width = b.clientWidth;
      }
    }

    return width;
  EOF

  VERIFY_SLEEP_PERIOD = 1.freeze
  VERIFY_RETRIES = 3.freeze

  def initialize(driver, dimension = nil)
    @driver = driver
    @dimension = dimension
  end

  def extract_viewport_width
    @driver.execute_script(JS_GET_VIEWPORT_WIDTH)
  end

  def extract_viewport_height
    @driver.execute_script(JS_GET_VIEWPORT_HEIGHT)
  end

  def extract_viewport_from_browser!
    @dimension = extract_viewport_from_browser
  end

  def extract_viewport_from_browser
    width, height = nil, nil
    begin
      width  = extract_viewport_width
      height = extract_viewport_height
    rescue => e
      Applitools::EyesLogger.error "Failed extracting viewport size using JavaScript: (#{e.message})"
    end

    if width.nil? || height.nil?
      Applitools::EyesLogger.info "Using window size as viewport size."

      width, height = *browser_size.values
      width, height = width.ceil, height.ceil

      if driver.landscape_orientation? && height > width
        width, height = height, width
      end
    end

    Applitools::Selenium::Dimension.new(width,height)
  end

  alias_method :viewport_size, :extract_viewport_from_browser

  def set
    if @dimension.is_a?(Hash) && @dimension.has_key?(:width) && @dimension.has_key?(:height)
      # If @dimension is hash of width/height, we convert it to a struct with width/height properties.
      @dimension = Struct.new(:width, :height).new(@dimension[:width], @dimension[:height])
    elsif !@dimension.respond_to?(:width) || !@dimension.respond_to?(:height)
      raise ArgumentError, "expected #{@dimension.inspect}:#{@dimension.class} to respond to #width and #height, or be "\
        ' a hash with these keys.'
    end

    set_browser_size(@dimension)
    verify_size(:browser_size)

    cur_viewport_size = extract_viewport_from_browser

    set_browser_size(Applitools::Selenium::Dimension.new((2 * browser_size.width) - cur_viewport_size.width,
      (2 * browser_size.height) - cur_viewport_size.height))
    verify_size(:viewport_size)
  end

  def verify_size(to_verify, sleep_time = VERIFY_SLEEP_PERIOD, retries = VERIFY_RETRIES)
    cur_size = nil

    retries.times do
      sleep(sleep_time)
      cur_size = send(to_verify)

      return if cur_size.values == @dimension.values
    end

    err_msg = "Failed setting #{to_verify} to #{@dimension.values} (current size: #{cur_size.values})"

    Applitools::EyesLogger.error(err_msg)
    raise Applitools::TestFailedError.new(err_msg)
  end

  def browser_size
    @driver.manage.window.size
  end

  def set_browser_size(other)
    @driver.manage.window.size = other
  end

  def to_hash
    Hash[@dimension.each_pair.to_a]
  end
end
