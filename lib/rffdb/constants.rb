module RubyFFDB
  # Data directory for DB storage
  DB_DATA = ENV["RFFDB_DB_DATA"] ? File.expand_path(ENV["RFFDB_DB_DATA"]) : File.expand_path(File.join("~", ".rffdb", "data"))
end