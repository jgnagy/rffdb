module RubyFFDB
  # Generic Cache Provider definition. Any subclass *must* implement the methods defined here.
  class CacheProvider
    # Used for pulling data from the cache
    def [](key)
      nil
    end
    
    # Used for storing data in the cache
    def []=(key, value)
      false
    end
  end
end