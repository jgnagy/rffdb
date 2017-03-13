$LOAD_PATH.push File.expand_path('../lib', __FILE__)
require 'rffdb/version'

Gem::Specification.new do |s|
  s.name        = 'rffdb'
  s.version     = RFFDB::VERSION
  s.date        = Time.now.strftime('%Y-%m-%d')
  s.summary     = 'Ruby FlatFile DB'
  s.description = 'A demonstration gem'
  s.authors     = ['Jonathan Gnagy']
  s.email       = 'jonathan.gnagy@gmail.com'
  s.homepage    = 'https://rubygems.org/gems/rffdb'

  s.required_ruby_version = '~> 2.0'
  s.files = [
    'lib/rffdb.rb',
    'lib/rffdb/constants.rb',
    'lib/rffdb/exception.rb',
    'lib/rffdb/exceptions/cache_exceptions.rb',
    'lib/rffdb/exceptions/document_exceptions.rb',
    'lib/rffdb/cache_provider.rb',
    'lib/rffdb/cache_providers/lru_cache.rb',
    'lib/rffdb/cache_providers/rr_cache.rb',
    'lib/rffdb/index.rb',
    'lib/rffdb/storage_engine.rb',
    'lib/rffdb/storage_engines/yaml_engine.rb',
    'lib/rffdb/storage_engines/json_engine.rb',
    'lib/rffdb/document.rb',
    'lib/rffdb/document_collection.rb',
    'lib/rffdb/version.rb',
    'README.markdown',
    'LICENSE'
  ]
  s.license = 'MIT'

  s.metadata['yard.run'] = 'yri'
  s.platform             = Gem::Platform::RUBY

  s.add_development_dependency 'bundler', '~> 1.12'
  s.add_development_dependency 'rake', '~> 10.0'
  s.add_development_dependency 'rspec', '~> 3.1'
  s.add_development_dependency 'rubocop', '~> 0.35'
  s.add_development_dependency 'yard',    '~> 0.8'
  s.add_development_dependency 'simplecov'
  s.add_development_dependency 'travis', '~> 1.8'
end
