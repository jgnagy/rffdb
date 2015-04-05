module RubyFFDB
  module CacheProviders
    # A simple Random Replacement (RR) cache implementation. Stores data in a
    # Hash, uses a dedicated Array for storing keys (and implementing the RR
    # algorithm), and doesn't bother storing access information for cache data.
    # It stores hit and miss counts for the entire cache (not for individual
    # keys). It also uses three mutexes for thread-safety: a write lock, a read
    # lock, and a metadata lock. The RRCache borrows nearly all its
    # functionality from the {LRUCache}, only overwriting the storage (and
    # therefore the revocation) method.
    class RRCache < LRUCache
      # Store some data (`value`) indexed by a `key`. If an object exists with
      # the same key, and the value is different, it will be overwritten.
      # Storing a new item when the cache is full causes the keys Array a random
      # entry to be evicted via a shuffling of the keys. Keys are stored in
      # the order in which they were inserted (not shuffled).
      #
      # @param key [Symbol] the index to use for referencing this cached item
      # @param value [Object] the data to cache
      def store(key, value)
        if has?(key)
          super(key, value)
        else
          if size >= @max_size
            invalidate(@keys.shuffle.first) until size < @max_size
          end

          @write_mutex.synchronize do
            @meta_mutex.synchronize { @keys << key }
            @data[key] = value
          end
        end
      end

      alias_method :[]=, :store
    end
  end
end
