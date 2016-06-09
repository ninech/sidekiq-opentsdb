# coding: utf-8

Gem::Specification.new do |spec|
  spec.name          = 'sidekiq-opentsdb'
  spec.version       = File.read(File.expand_path('../VERSION', __FILE__)).strip
  spec.authors       = ['David Dieulivol', 'Philippe Haessig']
  spec.email         = ['dadie@nine.ch', 'phil@nine.ch']

  spec.summary       = 'Sidekiq middleware to log useful sidekiq stats to OpenTSDB.'
  spec.description   = 'Sidekiq middleware to log useful sidekiq stats to OpenTSDB.'
  spec.homepage      = 'http://github.com/ninech/sidekiq-opentsdb'
  spec.license       = 'MIT'

  spec.files         = `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  spec.require_paths = ['lib']

  spec.add_runtime_dependency 'sidekiq', '>= 2.6'
  spec.add_runtime_dependency 'opentsdb', '~> 1.0'

  spec.add_development_dependency 'rspec', '~> 3.0'
  spec.add_development_dependency 'rake', '~> 11.1'
  spec.add_development_dependency 'pry', '~> 0'
end
