module RFFDB
  # Data directory for DB storage
  DB_DATA = if ENV['RFFDB_DB_DATA']
              File.expand_path(ENV['RFFDB_DB_DATA'])
            else
              File.expand_path(File.join('~', '.rffdb', 'data'))
            end
end
