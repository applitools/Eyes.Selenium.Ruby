class Applitools::ViewportSize

  JS_GET_VIEWPORT_HEIGHT =
      'var height = undefined;' +
      '  if (window.innerHeight) {height = window.innerHeight;}' +
      '  else if (document.documentElement ' +
        '&& document.documentElement.clientHeight) ' +
          '{height = document.documentElement.clientHeight;}' +
      '  else { var b = document.getElementsByTagName("body")[0]; ' +
                'if (b.clientHeight) {height = b.clientHeight;}' +
          '};' +
      'return height;'

  JS_GET_VIEWPORT_WIDTH  =
      'var width = undefined;' +
      ' if (window.innerWidth) {width = window.innerWidth;}' +
      ' else if (document.documentElement ' +
          '&& document.documentElement.clientWidth) ' +
            '{width = document.documentElement.clientWidth;}' +
      ' else { var b = document.getElementsByTagName("body")[0]; ' +
              'if (b.clientWidth) {' +
                'width = b.clientWidth;}' +
              '};' +
            'return width;'

  attr_reader :driver
  attr_accessor :dimension
  def initialize(driver, dimension=nil)
    @driver = driver
    @dimension = dimension
  end

  def extract_viewport_width
    driver.execute_script(JS_GET_VIEWPORT_WIDTH)
  end

  def extract_viewport_height
    driver.execute_script(JS_GET_VIEWPORT_HEIGHT)
  end

  def extract_viewport_from_browser!
    self.dimension = extract_viewport_from_browser
  end

  def extract_viewport_from_browser
    width, height = nil, nil
    begin
      width  = extract_viewport_width
      height = extract_viewport_height
    rescue => e
      EyesLogger.info "#{__method__}(): Failed to extract viewport size using Javascript: (#{e.message})"
    end
    if width.nil? || height.nil?
      EyesLogger.info "#{__method__}(): Using window size as viewport size."
      width, height = *browser_size.values
      width, height = width.ceil, height.ceil
      begin
        if driver.landscape_orientation? && height > width
          width, height = height, width
        end
      rescue NameError
        # Ignored. This error will occur for web based drivers, since they don't have the "orientation" attribute.
      end
    end
    Applitools::Dimension.new(width,height)
  end
  alias_method :viewport_size, :extract_viewport_from_browser

  def set
    if dimension.is_a?(Hash) && dimension.has_key?(:width) && dimension.has_key?(:height)
      # If dimension is hash of width/height, we convert it to a struct with width/height properties.
      self.dimension = Struct.new(:width, :height).new(dimension[:width], dimension[:height])
    elsif !dimension.respond_to?(:width) || !dimension.respond_to?(:height)
      raise ArgumentError, "expected #{dimension.inspect}:#{dimension.class}" +
                           ' to respond to #width and #height, or be a hash with these keys.'
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
