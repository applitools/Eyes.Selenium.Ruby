require 'capybara'

Dir[File.join(File.dirname(File.expand_path(__FILE__)), 'capybara', '*.rb')].sort.each do |f|
  require f
end

module Applitools
  extend Applitools::Capybara::CapybaraSettings
  register_capybara_driver
end
