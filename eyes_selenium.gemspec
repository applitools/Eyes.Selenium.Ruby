# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'applitools/version'

Gem::Specification.new do |spec|
  spec.name          = 'eyes_selenium'
  spec.version       = Applitools::VERSION
  spec.authors       = ['Applitools Team']
  spec.email         = ['team@applitools.com']
  spec.description   = 'Applitools Ruby SDK'
  spec.summary       = 'Applitools Ruby SDK'
  spec.homepage      = 'https://www.applitools.com'
  spec.license       = 'Apache License, Version 2.0'

  spec.files         = `git ls-files`.split($/)
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ['lib']

  spec.add_dependency 'selenium-webdriver', '>= 2.45.0'
  spec.add_dependency 'oily_png'
  spec.add_dependency 'faraday'

  spec.add_development_dependency 'bundler'
  spec.add_development_dependency 'rake'
  spec.add_development_dependency 'rspec', '>= 3'

  # Exclude debugging support on Travis CI, due to its incompatibility with jruby and older rubies.
  unless ENV['TRAVIS']
    spec.add_development_dependency 'pry'
    spec.add_development_dependency 'pry-byebug'
    spec.add_development_dependency 'pry-doc'
    spec.add_development_dependency 'pry-stack_explorer'
  end
end
