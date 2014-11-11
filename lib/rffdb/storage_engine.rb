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
    
    def self.all(type)
      []
    end

    def self.cache_size(type, size)
      @caches ||= {}
      @caches[type] ||= CacheProviders::LRUCache.new(size)
      @caches[type] = LRUCache.new(size) unless @caches[type].size == size
    end

    def self.cache_lookup(type, object_id)
      @caches ||= {}
      @caches[type] ||= CacheProviders::LRUCache.new
      @caches[type][object_id.to_s]
    end

    def self.cache_store(type, object_id, data)
      @caches ||= {}
      @caches[type] ||= CacheProviders::LRUCache.new
      @caches[type][object_id.to_s] = data
      return true
    end

    def self.cache(type)
      @caches ||= {}
      @caches[type] ||= CacheProviders::LRUCache.new
    end
  end
end