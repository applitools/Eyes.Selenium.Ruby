module Applitools
  class << self
    def require_dir(dir)
      Dir[File.join(File.dirname(File.expand_path(__FILE__)), 'applitools', dir, '*.rb')].sort.each do |f|
        require f
      end
    end
  end

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

require_relative 'applitools/method_tracer'
require_relative 'applitools/extensions'
require_relative 'applitools/version'

Applitools.require_dir 'base'
Applitools.require_dir 'utils'
Applitools.require_dir 'selenium'
Applitools.require_dir 'poltergeist'

require_relative 'applitools/eyes'
require_relative 'applitools/selenium_webdriver'
require_relative 'applitools/appium_driver'
require_relative 'applitools/watir_browser'

if defined? Sauce
  require 'applitools/sauce'
elsif defined? Capybara
  require 'applitools/capybara'
end
