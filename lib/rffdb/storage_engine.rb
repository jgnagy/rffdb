module RubyFFDB
  # Generic Storage Engine definition. Any subclass *must* implement or inherit the methods defined here (if any).
  class StorageEngine
    # Read locking by document type
    def self.read_lock(type, &block)
      @read_mutexes ||= {}
      @read_mutexes[type] ||= Mutex.new
      @read_mutexes[type].synchronize(&block)
    end

    # Write locking by document type, with implicit read locking
    def self.write_lock(type, &block)
      @write_mutexes ||= {}
      @write_mutexes[type] ||= Mutex.new
      @write_mutexes[type].synchronize do
        read_lock(type, &block)
      end
    end

    def self.store(type, object_id, data)
      false
    end

    def self.retrieve(type, object_id, use_caching = true)
      false
    end

    def self.flush
      false
    end

    def self.file_path(type, object_id)
      false
    end

    def self.all(type)
      []
    end

    def self.next_id(type)
      last_id = all(type)[-1]
      next_key = last_id.nil? ? 1 : (last_id + 1)
      if @highest_known_key and @highest_known_key >= next_key
        write_lock(type) { @highest_known_key += 1 }
      else
        write_lock(type) { @highest_known_key = next_key }
      end
    end

    # Set the cache provider to use for a document type
    # This completes flushes all cache.
    def self.cache_provider(document_type, cache_provider_class)
      unless cache_provider_class.instance_of? Class and cache_provider_class.ancestors.include?(CacheProvider)
        raise Exceptions::InvalidCacheProvider
      end
      @caches ||= {}
      @caches[document_type] = cache_provider_class.new
    end

    def self.cache_size(type, size)
      @caches ||= {}
      if @caches.has_key?(type)
        @caches[type] = @caches[type].class.new(size)
      else
        @caches[type] = CacheProviders::LRUCache.new(size)
      end
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