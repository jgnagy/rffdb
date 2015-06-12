module RubyFFDB
  # Generic Storage Engine definition. Any subclass *must* implement or inherit
  # the methods defined here (if any).
  class StorageEngine
    # Read locking by document type
    # @param type [Document] implements the equivalent of table-level
    #   read-locking on this {Document} type
    def self.read_lock(type, &block)
      @read_mutexes ||= {}
      @read_mutexes[type] ||= Mutex.new
      @read_mutexes[type].synchronize(&block)
    end

    # Write locking by document type, with implicit read locking
    # @param type [Document] implements the equivalent of table-level
    #   write-locking on this {Document} type
    def self.write_lock(type, &block)
      @write_mutexes ||= {}
      @write_mutexes[type] ||= Mutex.new
      @write_mutexes[type].synchronize do
        read_lock(type, &block)
      end
    end

    # Store data
    # This method should be overridden in subclasses.
    # @param type [Document] type of {Document} to store
    # @param object_id [Object] unique identifier for the data to store
    # @param data [Object] data to be stored
    def self.store(_type, _object_id, _data)
      false
    end

    # Retrieve some stored data
    # This method should be overridden in subclasses.
    # @param type [Document] type of {Document} to retrieve
    # @param object_id [Object] unique identifier for the stored data
    # @param use_caching [Boolean] attempt to pull the data from cache (or not)
    def self.retrieve(_type, _object_id, _use_caching = true)
      false
    end

    # Flush all changes to disk (usually done automatically)
    # This method should be overridden in subclasses.
    def self.flush
      false
    end

    # The full path to a stored (or would-be stored) {Document}
    # This method should be overridden in subclasses.
    # @param type [Document] the document type
    # @param object_id [Object] unique identifier for the document
    def self.file_path(_type, _object_id)
      false
    end

    # Return all known instances of a {Document}
    # This method should be overridden in subclasses.
    # @param type [Document] the document type
    # @return [Array]
    def self.all(_type)
      []
    end

    # Determine the next unique identifier available for a {Document} type
    # @param type [Document] the document type
    # @return [Fixnum]
    def self.next_id(type)
      last_id = all(type)[-1]
      next_key = last_id.nil? ? 1 : (last_id + 1)
      if @highest_known_key && @highest_known_key >= next_key
        write_lock(type) { @highest_known_key += 1 }
      else
        write_lock(type) { @highest_known_key = next_key }
      end
    end

    # Set the cache provider to use for a document type
    # This completely flushes all cache.
    # @param document_type [Document] the document type
    # @param cache_provider_class [CacheProvider] the type {CacheProvider}
    #   subclass for caching
    def self.cache_provider(document_type, cache_provider_class)
      unless cache_provider_class.instance_of?(Class) &&
             cache_provider_class.ancestors.include?(CacheProvider)
        fail Exceptions::InvalidCacheProvider
      end
      @caches ||= {}
      @caches[document_type] = cache_provider_class.new
    end

    # Set the maximum size of a cache, based on {Document} type
    # @param type [Document] the document type
    # @param size [Fixnum] the maximum size of the cache
    def self.cache_size(type, size)
      @caches ||= {}
      if @caches.key?(type)
        @caches[type] = @caches[type].class.new(size)
      else
        @caches[type] = CacheProviders::LRUCache.new(size)
      end
    end

    # Attempt to retrieve an item from the {Document} type's cache instance
    # @param type [Document] the document type
    # @param object_id [Object] unique identifier for the document
    def self.cache_lookup(type, object_id)
      @caches ||= {}
      @caches[type] ||= CacheProviders::LRUCache.new
      @caches[type][object_id.to_s]
    end

    # Store some data in the cache for the {Document} type
    # @param type [Document] the document type
    # @param object_id [Object] unique identifier for the document
    # @param data [Object] data to be stored
    # @return [Boolean]
    def self.cache_store(type, object_id, data)
      @caches ||= {}
      @caches[type] ||= CacheProviders::LRUCache.new
      @caches[type][object_id.to_s] = data
      true
    end

    # Allow access to the cache instance directly (kind of dangerous but helpful
    # for troubleshooting)
    # @param type [Document] the document type
    # @return [CacheProvider]
    def self.cache(type)
      @caches ||= {}
      @caches[type] ||= CacheProviders::LRUCache.new
    end

    # Allows direct access to an index for a Document type and column
    # @param type [Document] the document type
    # @param column [String,Symbol] the column / attribute for the index
    def self.index(type, column)
      @indexes ||= {}
      @indexes[type] ||= {}
      @indexes[type][column.to_sym] ||= Index.new(type, column.to_sym)
    end

    # Update the index for a column
    # @param type [Document] the document type
    # @param column [String,Symbol] the column / attribute for the index
    # @param object_id [Object] unique identifier for the document
    # @param data [String] column data to be stored
    def self.index_update(type, column, object_id, data)
      i = index(type, column)
      # Delete all previous entries in this index
      oldkeys = i.keys.collect { |k| k if i.get(k).include?(object_id) }.compact
      oldkeys.each do |k|
        i.delete(k, object_id)
      end

      # Add the new indexed version
      i.put(data, object_id)
    end

    # Query an index for column data
    # @param type [Document] the document type
    # @param column [String,Symbol] the column / attribute for the index
    # @param data [String] column data to use for the lookup
    def self.index_lookup(type, column, data, operator = '==')
      i = index(type, column)
      i.query(data, operator)
    end
  end
end
