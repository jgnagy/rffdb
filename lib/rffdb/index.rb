module RubyFFDB
  class Index
    def initialize(type, column)
      @type = type
      @column = column
      FileUtils.mkdir_p(File.dirname(file_path))
      GDBM.open(file_path, 0664, GDBM::WRCREAT) do
        # Index initialized
      end
    end

    def file_path
      File.join(
        DB_DATA,
        @type.to_s.gsub('::', '__'),
        'indexes',
        @column.to_s + '.index'
      )
    end

    def get(key)
      GDBM.open(file_path, 0664, GDBM::READER) do |index|
        Marshal.load index.fetch(key.to_s, Marshal.dump([]))
      end
    end

    def put(key, value)
      previous = get(key)
      GDBM.open(file_path, 0664, GDBM::WRCREAT) do |index|
        index[key.to_s] = Marshal.dump((previous + [value]).uniq)
      end
    end

    # Remove a specific Document association with a key
    def delete(key, value)
      previous = get(key)
      GDBM.open(file_path, 0664, GDBM::WRCREAT) do |index|
        index[key.to_s] = Marshal.dump((previous - [value]).uniq)
      end
    end

    # Remove all associations with a specific key (column data)
    def truncate(key)
      GDBM.open(file_path, 0664, GDBM::WRCREAT) do |index|
        index.delete(key.to_s)
      end
    end

    # All keys (column data) in the index
    # @return [Array] An array of object ids
    def keys
      GDBM.open(file_path, 0664, GDBM::READER) do |index|
        index.keys
      end
    end

    # Evict keys (column data) with no associated Documents
    def prune
      GDBM.open(file_path, 0664, GDBM::WRCREAT) do |index|
        index.delete_if { |key, value| Marshal.load(value).empty? }
      end
    end
  end
end
