$:.push File.expand_path("../lib", __FILE__)
require "rffdb/version"

Gem::Specification.new do |s|
  s.name        = 'rffdb'
  s.version     = RubyFFDB::VERSION
  s.date        = '2014-06-30'
  s.summary     = "Ruby FlatFile DB"
  s.description = "A demonstration gem"
  s.authors     = ["Jonathan Gnagy"]
  s.email       = 'jonathan.gnagy@gmail.com'
  s.files       = [
    "lib/rffdb.rb",
    "lib/rffdb/exception.rb",
    "lib/rffdb/exceptions/cache_exceptions.rb",
    "lib/rffdb/exceptions/document_exceptions.rb",
    "lib/rffdb/cache_provider.rb",
    "lib/rffdb/cache_providers/lru_cache.rb",
    "lib/rffdb/cache_providers/rr_cache.rb",
    "lib/rffdb/storage_engine.rb",
    "lib/rffdb/storage_engines/yaml_engine.rb",
    "lib/rffdb/storage_engines/json_engine.rb",
    "lib/rffdb/document.rb",
    "lib/rffdb/document_collection.rb",
    "lib/rffdb/version.rb",
    "LICENSE"
  ]
  s.license     = 'MIT'
end