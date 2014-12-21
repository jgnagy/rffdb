module RubyFFDB
  # Generic Storage Engine definition. Any subclass *must* implement or inherit the methods defined here (if any).
  class StorageEngine
    # Read locking by document type
    # @param type [Document] implements the equivalent of table-level read-locking on this {Document} type 
    def self.read_lock(type, &block)
      @read_mutexes ||= {}
      @read_mutexes[type] ||= Mutex.new
      @read_mutexes[type].synchronize(&block)
    end

    # Write locking by document type, with implicit read locking
    # @param type [Document] implements the equivalent of table-level write-locking on this {Document} type
    def self.write_lock(type, &block)
      @write_mutexes ||= {}
      @write_mutexes[type] ||= Mutex.new
      @write_mutexes[type].synchronize do
        read_lock(type, &block)
      end
    end

    # Store data
    # @param type [Document] type of {Document} to store
    # @param object_id [Object] unique identifier for the data to store (usually an Integer)
    # @param data [Object] data to be stored
    def self.store(type, object_id, data)
      false
    end

    # Retrieve some stored data
    # @param type [Document] type of {Document} to retrieve
    # @param object_id [Object] unique identifier for the stored data (usually an Integer)
    # @param use_caching [Boolean] attempt to pull the data from cache (or not)
    def self.retrieve(type, object_id, use_caching = true)
      false
    end

    # Flush all changes to disk (usually done automatically)
    def self.flush
      false
    end

    # The full path to a stored (or would-be stored) {Document}
    # @param type [Document] the document type
    # @param object_id [Object] unique identifier for the document (usually an Integer)
    def self.file_path(type, object_id)
      false
    end

    # Return all known instances of a {Document}
    # @param type [Document] the document type
    # @return [Array]
    def self.all(type)
      []
    end

    # Determine the next unique identifier available for a {Document} type
    # @param type [Document] the document type
    # @return [Fixnum]
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
    # This completely flushes all cache.
    # @param document_type [Document] the document type
    # @param cache_provider_class [CacheProvider] the type of {CacheProvider} to use
    def self.cache_provider(document_type, cache_provider_class)
      unless cache_provider_class.instance_of? Class and cache_provider_class.ancestors.include?(CacheProvider)
        raise Exceptions::InvalidCacheProvider
      end
      @caches ||= {}
      @caches[document_type] = cache_provider_class.new
    end

    # Set the maximum size of a cache, based on {Document} type
    # @param type [Document] the document type
    # @param size [Fixnum] the maximum size of the cache
    def self.cache_size(type, size)
      @caches ||= {}
      if @caches.has_key?(type)
        @caches[type] = @caches[type].class.new(size)
      else
        @caches[type] = CacheProviders::LRUCache.new(size)
      end
    end

    # Attempt to retrieve an item from the {Document} type's cache instance
    # @param type [Document] the document type
    # @param object_id [Object] unique identifier for the document (usually an Integer)
    def self.cache_lookup(type, object_id)
      @caches ||= {}
      @caches[type] ||= CacheProviders::LRUCache.new
      @caches[type][object_id.to_s]
    end

    # Store some data in the cache for the {Document} type
    # @param type [Document] the document type
    # @param object_id [Object] unique identifier for the document (usually an Integer)
    # @param data [Object] data to be stored
    # @return [Boolean]
    def self.cache_store(type, object_id, data)
      @caches ||= {}
      @caches[type] ||= CacheProviders::LRUCache.new
      @caches[type][object_id.to_s] = data
      return true
    end

    # Allow access to the cache instance directly (kind of dangerous but helpful for troubleshooting)
    # @param type [Document] the document type
    # @return [CacheProvider]
    def self.cache(type)
      @caches ||= {}
      @caches[type] ||= CacheProviders::LRUCache.new
    end
  end
end