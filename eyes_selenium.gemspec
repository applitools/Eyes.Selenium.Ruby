lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)

require 'applitools/version'

Gem::Specification.new do |spec|
  spec.name          = 'eyes_selenium'
  spec.version       = Applitools::VERSION
  spec.authors       = ['Applitools Team']
  spec.email         = ['team@applitools.com']
  spec.description   = 'Applitools Ruby Images SDK'
  spec.summary       = 'Applitools Ruby Images SDK'
  spec.homepage      = 'https://www.applitools.com'
  spec.license       = 'Apache License, Version 2.0'

  spec.files         = `git ls-files lib/applitools/selenium`.split($RS) +
    ['lib/eyes_selenium.rb', 'lib/applitools/capybara.rb', 'lib/applitools/version.rb']
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = %w(lib)
  spec.add_dependency 'eyes_core', '>= 3.0.1'
  spec.add_dependency 'capybara'
end
