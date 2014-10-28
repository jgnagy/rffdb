module RubyFFDB
  class StorageEngine
    def self.store(type, object_id, data)
      false
    end

    def self.retrieve(type, object_id, use_caching = true)
      false
    end

    def self.flush
      false
    end

    def self.next_id(type)
      false
    end
    
    def self.file_path(type, object_id)
      false
    end
    
    def self.cache_size(type, size)
      @cache_sizes ||= {}
      @cache_sizes[type] = size
    end
    
    def self.cache_lookup(type, object_id)
      @cache ||= {}
      @cache[type] ||= OpenStruct.new
      return @cache[type][(type.to_s + object_id.to_s).to_sym]
    end
    
    def self.cache_store(type, object_id, data)
      @cache ||= {}
      @cache[type] ||= OpenStruct.new
      @cache[type][(type.to_s + object_id.to_s).to_sym] = data
      return true
    end
  end
end