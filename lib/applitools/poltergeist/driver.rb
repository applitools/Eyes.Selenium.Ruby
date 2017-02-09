# Applitools::Poltergeist::Driver is a small class implemented
# for compatibility with Applitools API.
# It gives required for Applitools methods to Poltergeist driver.
module Applitools::Poltergeist
  class Driver < Applitools::Selenium::Driver
    def initialize(eyes, options)
      options[:driver].extend Applitools::Poltergeist::ApplitoolsCompatible
      super(eyes, options)
    end
  end
end
