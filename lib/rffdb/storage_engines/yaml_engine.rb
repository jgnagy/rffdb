module RubyFFDB
  module StorageEngines
    class YamlEngine < StorageEngine
      # TODO add support for sharding since directories will fill up quickly
      require 'yaml'
      def self.store(type, object_id, data)
        path = file_path(type, object_id)
        FileUtils.mkdir_p(File.dirname(path))
        File.open(path, "w") do |file|
          file.puts YAML.dump(data)
        end
        cache_store(type, object_id, data)
        return true
      end
      
      def self.retrieve(type, object_id, use_caching = true)
        result = nil
        begin
          result = cache_lookup(type, object_id) if use_caching
          result ||= YAML.load_file(file_path(type, object_id))
          cache_store(type, object_id, result)
        rescue => e
          puts e.message
        end
        return result
      end

      def self.next_id(type)
        # lists the files in the directory and grabs the next id
        directory_glob = Dir.glob(File.join(File.dirname(file_path(type, 0)), "*.yml"))
        if directory_glob and !directory_glob.empty?
          return Integer(File.basename(directory_glob.sort.last, ".yml")) + 1
        else
          return 1
        end
      end
      
      def self.file_path(type, object_id)
        File.join(type.to_s.gsub('::', "__"), 'documents', object_id.to_s + ".yml")
      end
    end
  end
end