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

    def delete(key, value)
      previous = get(key)
      GDBM.open(file_path, 0664, GDBM::WRCREAT) do |index|
        index[key.to_s] = Marshal.dump((previous - [value]).uniq)
      end
    end

    def truncate(key)
      GDBM.open(file_path, 0664, GDBM::WRCREAT) do |index|
        index.delete(key.to_s)
      end
    end

    def keys
      GDBM.open(file_path, 0664, GDBM::READER) do |index|
        index.keys
      end
    end
  end
end
