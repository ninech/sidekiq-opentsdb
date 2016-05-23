# coding: utf-8

lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'sidekiq/opentsdb/version'

Gem::Specification.new do |spec|
  spec.name          = 'sidekiq-opentsdb'
  spec.version       = Sidekiq::Opentsdb::VERSION
  spec.authors       = ['David Dieulivol']
  spec.email         = ['dadie@nine.ch']

  spec.summary       = 'Sidekiq middleware to log useful sidekiq stats to OpenTSDB.'
  spec.description   = 'Sidekiq middleware to log useful sidekiq stats to OpenTSDB.'
  spec.homepage      = 'http://github.com/ninech/'
  spec.license       = 'MIT'

  spec.files         = `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  spec.bindir        = 'exe'
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ['lib']

  spec.add_runtime_dependency 'sidekiq', '>= 2.6'
  spec.add_runtime_dependency 'opentsdb'

  spec.add_development_dependency 'bundler', '~> 1.12'
  spec.add_development_dependency 'rspec', '~> 3.0'
  spec.add_development_dependency 'pry'
end
