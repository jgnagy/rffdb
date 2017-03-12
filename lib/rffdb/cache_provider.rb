module RFFDB
  # Generic Cache Provider definition. Any subclass *must* implement or inherit
  # the methods defined here (if any).
  class CacheProvider
    # Used for pulling data from the cache
    def [](_key)
      nil
    end

    # Used for storing data in the cache
    def []=(_key, _value)
      false
    end
  end
end
