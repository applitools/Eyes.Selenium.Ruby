module Applitools
  ROOT_DIR = File.join(File.dirname(File.expand_path(__FILE__)), 'applitools').freeze

  Dir["#{ROOT_DIR}/*.rb"].each {|f| require f}
  Dir["#{ROOT_DIR}/**/*.rb"].each {|f| require f}

  class EyesError < StandardError; end
  class EyesAbort < EyesError; end

  class TestFailedError < StandardError
    attr_accessor :test_results

    def initialize(message, test_results = nil)
      super(message)

      @test_results = test_results
    end
  end

  class NewTestError < TestFailedError; end
end
