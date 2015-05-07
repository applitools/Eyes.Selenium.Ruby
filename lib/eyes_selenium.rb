module Applitools
  require 'applitools/eyes_logger'

  ROOT_DIR = File.join(File.dirname(File.expand_path(__FILE__)), 'applitools').freeze

  module Selenium
    Dir["#{ROOT_DIR}/selenium/**/*.rb"].each {|f| require f}
  end

  module Utils
    Dir["#{ROOT_DIR}/utils/**/*.rb"].each {|f| require f}
  end

  class EyesError < StandardError; end
  class EyesAbort < EyesError; end

  class TestFailedError < StandardError
    attr_accessor :test_results
    def initialize(message, test_results=nil)
      super(message)
      @test_results = test_results
    end
  end
  class NewTestError < TestFailedError; end
end
