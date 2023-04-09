# frozen_string_literal: true

lib = File.expand_path('lib', __dir__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'logging/version'

Gem::Specification.new do |spec|
  spec.name          = 'logging'
  spec.version       = Logging::VERSION
  spec.required_ruby_version = '>= 2.6.3'
  spec.authors       = ['Rustam Mamedov']
  spec.email         = ['kharkivrem@gmail.com']

  spec.summary       = 'Logging in the Real World'
  spec.license       = 'MIT'

  spec.files         = `git ls-files -z`.split("\x0").reject do |f|
    f.match(%r{^(test|spec|features)/})
  end
  spec.bindir        = 'exe'
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ['lib']

  spec.add_runtime_dependency 'dotenv', '~> 2.2', '>= 2.2.1'
  spec.add_development_dependency 'activesupport', '~> 6.0.0'
  spec.add_development_dependency 'bundler', '~> 2.4.10'
  spec.add_development_dependency 'json', '~> 2.6.3'
  spec.add_development_dependency 'pry', '~> 0.10.4'
  spec.add_development_dependency 'rack', '~> 2.0'
  spec.add_development_dependency 'rake', '~> 10.0'
  spec.add_development_dependency 'rspec', '~> 3.0'
  spec.add_development_dependency 'rspec-mocks', '~> 3.6', '>= 3.6.0'
  spec.add_development_dependency 'rubocop', '~> 0.48'
end
