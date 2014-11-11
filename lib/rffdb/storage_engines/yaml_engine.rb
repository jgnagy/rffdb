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
        return result.dup # Return a duplicate to support caching
      end

      # Lazily grab all document ids in use
      def self.all(type)
        directory_glob = Dir.glob(File.join(File.dirname(file_path(type, 0)), "*.yml"))
        if directory_glob and !directory_glob.empty?
          directory_glob.map {|doc| Integer(File.basename(doc, ".yml"))}.sort
        else
          []
        end
      end

      def self.next_id(type)
        last_id = all(type)[-1]
        last_id.nil? ? 1 : (last_id + 1)
      end

      def self.file_path(type, object_id)
        File.join(type.to_s.gsub('::', "__"), 'documents', object_id.to_s + ".yml")
      end
    end
  end
end