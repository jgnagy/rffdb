module RubyFFDB
  module StorageEngines
    class JsonEngine < StorageEngine
      # TODO add support for sharding since directories will fill up quickly
      require 'json'

      def self.store(type, object_id, data)
        path = file_path(type, object_id)
        write_lock(type) do
          FileUtils.mkdir_p(File.dirname(path))
          File.open(path, "w") do |file|
            file.puts JSON.dump(data)
          end
          cache_store(type, object_id, data)
        end
        return true
      end

      def self.retrieve(type, object_id, use_caching = true)
        result = nil
        begin
          result = cache_lookup(type, object_id) if use_caching
          unless result
            read_lock(type) do
              file = File.open(file_path(type, object_id), "r")
              result = JSON.load(file)
              file.close
            end
          end
          cache_store(type, object_id, result)
        rescue => e
          puts e.message
        end
        return result.dup # Return a duplicate to support caching
      end

      # Lazily grab all document ids in use
      def self.all(type)
        directory_glob = read_lock(type) { Dir.glob(File.join(File.dirname(file_path(type, 0)), "*.json")) }
        if directory_glob and !directory_glob.empty?
          directory_glob.map {|doc| Integer(File.basename(doc, ".json"))}.sort
        else
          []
        end
      end

      def self.file_path(type, object_id)
        File.join(type.to_s.gsub('::', "__"), 'documents', object_id.to_s + ".json")
      end
    end
  end
end