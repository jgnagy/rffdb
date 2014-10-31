module RubyFFDB
  module StorageEngines
    class JsonEngine < StorageEngine
      # TODO add support for sharding since directories will fill up quickly
      require 'json'
      def self.store(type, object_id, data)
        path = file_path(type, object_id)
        FileUtils.mkdir_p(File.dirname(path))
        File.open(path, "w") do |file|
          file.puts JSON.dump(data)
        end
        cache_store(type, object_id, data)
        return true
      end

      def self.retrieve(type, object_id, use_caching = true)
        result = nil
        begin
          result = cache_lookup(type, object_id) if use_caching
          unless result
            file = File.open(file_path(type, object_id), "r")
            result = JSON.load(file)
            file.close
          end
          cache_store(type, object_id, result)
        rescue => e
          puts e.message
        end
        return result.dup
      end

      def self.next_id(type)
        # lists the files in the directory and grabs the next id
        directory_glob = Dir.glob(File.join(File.dirname(file_path(type, 0)), "*.json"))
        if directory_glob and !directory_glob.empty?
          return Integer(File.basename(directory_glob.sort.last, ".json")) + 1
        else
          return 1
        end
      end

      def self.file_path(type, object_id)
        File.join(type.to_s.gsub('::', "__"), 'documents', object_id.to_s + ".json")
      end
    end
  end
end