require 'capybara'

Applitools.require_dir 'selenium/capybara'

module Applitools
  extend Applitools::Selenium::Capybara::CapybaraSettings
  register_capybara_driver
end
