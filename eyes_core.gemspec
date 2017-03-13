# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'applitools/version'

module_files = `git ls-files lib/applitools/images`.split($RS) + `git ls-files lib/applitools/selenium`.split($RS) +
  ['lib/eyes_images', 'lib/applitools/capybara', 'lib/eyes_selenium']

CURRENT_RUBY_VERSION = Gem::Version.new RUBY_VERSION

RUBY_1_9_3 = Gem::Version.new '1.9.3'
RUBY_2_0_0 = Gem::Version.new '2.0.0'
RUBY_2_2_2 = Gem::Version.new '2.2.2'
RUBY_2_4_0 = Gem::Version.new '2.4.0'

RUBY_KEY = [RUBY_1_9_3, RUBY_2_0_0, RUBY_2_2_2, RUBY_2_4_0].select { |v| v <= CURRENT_RUBY_VERSION }.last

EYES_GEM_SPECS = {
  RUBY_1_9_3 => proc do |spec|
    spec.add_development_dependency 'mime-types', ['~> 2.99.0']
    spec.add_development_dependency 'rack', ['~> 1.6.0']
    spec.add_development_dependency 'tomlrb', ['<= 1.2.2']
    spec.add_development_dependency 'rubocop', ['~> 0.41.1']
    spec.add_development_dependency 'cmdparse', ['= 2.0.2']
    spec.add_development_dependency 'net-ssh', ['<= 3.0.0']
    spec.add_development_dependency 'net-http-persistent', ['< 3.0.0']
    spec.add_development_dependency 'sauce'
    spec.add_dependency 'nokogiri', '~> 1.6.0'
    spec.add_dependency 'public_suffix', '< 1.5.0'
    spec.add_dependency 'appium_lib', '< 9.1'
  end,
  RUBY_2_0_0 => proc do |spec|
    spec.add_development_dependency 'rack', ['~> 1.6.0']
    spec.add_development_dependency 'rubocop', ['<= 0.46.0']
    spec.add_development_dependency 'net-http-persistent', ['< 3.0.0']
    spec.add_development_dependency 'sauce'
    spec.add_dependency 'nokogiri', '~> 1.6.0'
    spec.add_development_dependency 'appium_lib', '< 9.1'
  end,
  RUBY_2_2_2 => proc do |spec|
    spec.add_development_dependency 'rubocop', ['<= 0.46.0']
    spec.add_development_dependency 'sauce'
    spec.add_development_dependency 'appium_lib'
  end,
  RUBY_2_4_0 => proc do |spec|
    spec.add_development_dependency 'appium_lib'
    spec.add_development_dependency 'rubocop', ['<= 0.46.0']
  end
}.freeze

Gem::Specification.new do |spec|
  spec.name          = 'eyes_core'
  spec.version       = Applitools::VERSION
  spec.authors       = ['Applitools Team']
  spec.email         = ['team@applitools.com']
  spec.description   = 'Applitools Ruby SDK'
  spec.summary       = 'Applitools Ruby SDK'
  spec.homepage      = 'https://www.applitools.com'
  spec.license       = 'Apache License, Version 2.0'

  spec.files         = `git ls-files lib/applitools`.split($RS) + ['lib/eyes_core.rb'] - module_files
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})

  spec.extensions    = ['ext/applitools/extconf.rb']
  spec.require_paths = %w(lib ext)

  spec.add_dependency 'oily_png', '~> 1.2'
  spec.add_dependency 'chunky_png', '= 1.3.6'
  spec.add_dependency 'faraday'
  spec.add_dependency 'oj'

  spec.add_development_dependency 'bundler'
  spec.add_development_dependency 'rake'
  spec.add_development_dependency 'rspec', '>= 3'
  spec.add_development_dependency 'watir-webdriver'

  EYES_GEM_SPECS[RUBY_KEY].call spec

  # Exclude debugging support on Travis CI, due to its incompatibility with jruby and older rubies.
  unless ENV['TRAVIS'] || CURRENT_RUBY_VERSION < Gem::Version.new('2.0.0')
    spec.add_development_dependency 'pry'
    spec.add_development_dependency 'pry-byebug'
    spec.add_development_dependency 'byebug'
    spec.add_development_dependency 'pry-doc'
    spec.add_development_dependency 'pry-stack_explorer'
  end
end
