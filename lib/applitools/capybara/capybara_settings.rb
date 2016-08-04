module Applitools::Capybara
  module CapybaraSettings
    def register_capybara_driver options={}
      Capybara.register_driver :eyes do |app|
        Applitools::Capybara::Driver.new app, options
      end
      Capybara.default_driver = :eyes
      Capybara.javascript_driver = :eyes
    end
  end
end