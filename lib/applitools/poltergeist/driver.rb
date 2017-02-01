require 'capybara/poltergeist'

module Applitools::Poltergeist
  class Driver < Applitools::Selenium::Driver
    def initialize(eyes, options)
      options[:driver].extend Applitools::Poltergeist::ApplitoolsCompatible
      super(eyes, options)
    end
  end
end
