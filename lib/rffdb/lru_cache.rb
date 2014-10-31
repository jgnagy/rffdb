module RubyFFDB
  class LRUCache
    attr_reader :max_size, :keys
    def initialize(max_size = 100)
      raise Exceptions::InvalidCacheSize unless max_size.kind_of?(Integer)

      @max_size = max_size
      @hits     = 0
      @misses   = 0
      @keys     = []
      @data     = {}
    end

    def has?(key)
      @keys.include?(key)
    end

    alias_method :has_key?, :has?
    alias_method :include?, :has?

    def size
      @keys.size
    end

    def to_hash
      @data.dup
    end

    def values
      @data.values
    end

    def each
      @data.each
    end

    def invalidate(key)
      @keys.delete(key)
      @data.delete(key)
    end

    alias_method :delete, :invalidate

    def truncate
      @keys   = []
      @data   = {}
    end

    def flush
      truncate
      @hits, @misses = 0, 0
    end

    def store(key, value)
      if size >= @max_size
        invalidate(@keys.first) until size < @max_size
      end
      invalidate(key)
      @keys << key
      @data[key] = value
    end

    alias_method "[]=".to_sym, :store

    def retrieve(key)
      if has?(key)
        @hits += 1
        store(key, @data[key])
      else
        @misses += 1
        nil
      end
    end

    alias_method "[]".to_sym, :retrieve

    def marshal_dump
      [@max_size, @hits, @misses, @keys, @data]
    end

    def marshal_load(array)
      @max_size, @hits, @misses, @keys, @data = array
    end
  end
end