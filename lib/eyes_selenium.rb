module Applitools
  ROOT_DIR = File.join(File.dirname(File.expand_path(__FILE__)), 'applitools').freeze

  Dir["#{ROOT_DIR}/*.rb"].sort.each { |f| require f }
  Dir["#{ROOT_DIR}/**/*.rb"].sort.each { |f| require f }

  class EyesError < StandardError; end
  class EyesAbort < EyesError; end
  class EyesIllegalArgument < EyesError; end

  class AbstractMethodCalled < EyesError
    attr_accessor :method_name, :object

    def initialize(method_name, object)
      @method = method_name
      @object = object
      message = "Abstract method #{method_name} is called for #{object}. "\
          'You should override it in a descendant class.'
      super message
    end
  end

  class TestFailedError < StandardError
    attr_accessor :test_results

    def initialize(message, test_results = nil)
      super(message)

      @test_results = test_results
    end
  end

  class NewTestError < TestFailedError; end
end
