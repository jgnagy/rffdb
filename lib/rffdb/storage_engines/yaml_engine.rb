module RFFDB
  module StorageEngines
    # The YAML Storage Engine
    class YamlEngine < StorageEngine
      # TODO: add support for sharding since directories will fill up quickly
      require 'yaml'

      def self.store(type, object_id, data)
        path = file_path(type, object_id)
        write_lock(type) do
          FileUtils.mkdir_p(File.dirname(path))
          File.open(path, 'w') do |file|
            file.puts YAML.dump(data)
          end
          type.structure.collect { |k, v| k if v[:index] }.compact.each do |col|
            index_update(type, col, object_id, data[col.to_s])
          end
          cache_store(type, object_id, data)
        end
        true
      end

      def self.retrieve(type, object_id, use_caching = true)
        result = nil
        begin
          result = cache_lookup(type, object_id) if use_caching
          read_lock(type) do
            result ||= YAML.load_file(file_path(type, object_id))
          end
          write_lock(type) do
            cache_store(type, object_id, result)
          end
        rescue => e
          puts e.message
        end
        result.dup # Return a duplicate to support caching
      end

      # Lazily grab all document ids in use
      def self.all(type)
        directory_glob = read_lock(type) do
          Dir.glob(File.join(File.dirname(file_path(type, 0)), '*.yml'))
        end
        if directory_glob && !directory_glob.empty?
          directory_glob.map { |doc| Integer(File.basename(doc, '.yml')) }.sort
        else
          []
        end
      end

      def self.file_path(type, object_id)
        File.join(
          DB_DATA,
          type.to_s.gsub('::', '__'),
          'documents',
          object_id.to_s + '.yml'
        )
      end
    end
  end
end
