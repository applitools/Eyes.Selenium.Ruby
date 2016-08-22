require 'capybara'

Applitools.require_dir 'capybara'

module Applitools
  extend Applitools::Capybara::CapybaraSettings
  register_capybara_driver
end
