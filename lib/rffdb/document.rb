module RubyFFDB
  class Document
    include Comparable
    attr_reader :id

    # @raise [Exceptions::NoSuchDocument] retrieved a non-existing document
    def initialize(existing_id = false, lazy = true)
      if existing_id
        @id  = existing_id
        fail Exceptions::NoSuchDocument unless File.exist?(file_path)
        if lazy
          @lazy = true
        else
          reload(true)
          @lazy = false
        end
        @saved = true
      else
        @id = storage.next_id(self.class)
        @data = {}
        # relative to database root
        @saved = false
      end
      @read_lock  = Mutex.new
      @write_lock = Mutex.new
    end

    # The location of the flat-file
    # @return [String] flat-file used to store this document (may not exist yet)
    def file_path
      storage.file_path(self.class, @id)
    end

    # Commit the document to storage
    # @return [Boolean]
    def commit
      @read_lock.synchronize do
        @write_lock.synchronize do
          unless @saved
            storage.store(self.class, @id, @data.dup)
          end
          @saved = true
        end
      end
    end

    alias_method :save, :commit

    # Has this documented been committed to storage?
    # @return [Boolean]
    def committed?
      @saved
    end

    # Retrieve the stored data from disk, never using cache. Allows forcing to
    # overwrite uncommitted changes.
    # @raise [Exceptions::PendingChanges] if attempting to reload with
    #   uncommitted changes (and if `force` is false)
    def reload(force = false)
      if committed? || force
        @read_lock.synchronize do
          @write_lock.synchronize do
            @data = storage.retrieve(self.class, @id, false)
          end
        end
      else
        fail Exceptions::PendingChanges
      end
      @read_lock.synchronize do
        @write_lock.synchronize { @saved = true }
      end
    end

    # Overwrites the document's data, either from disk or from cache. Useful for
    # lazy-loading and not typically used directly. Since data might have been
    # pulled from cache, this can lead to bizarre things if not used carefully
    # and things rely on #committed? or @saved.
    def refresh
      @write_lock.synchronize do
        @data = storage.retrieve(self.class, @id)
        @saved = true
      end
    end

    # Currently an alias for #new, but used as a wrapper in case more work needs
    # to be done before pulling a document from the storage engine (such as
    # sanitizing input, etc)
    def self.load(id)
      new(id)
    end

    singleton_class.send(:alias_method, :get, :load)

    # This DSL method is used to define the schema for a document. It sets up
    # all data access for the class, and allows specifying strict checks
    # on that schema during its use, such as validations, class types, regexp
    # formatting, etc.
    #
    # @param name [Symbol] the unique name of the attribute
    # @option options [Class] :class (Object) the expected object class for
    #   this attribute
    # @option options [Regexp] :format a regular expression for the required
    #   format of the attribute (for any :class that supports #.to_s)
    # @option options [Array, Symbol] :validate either a symbol or array of
    #   symbols referencing the instance method(s) to use to validate this
    #   attribute
    # @option options [Boolean] :unique should this attribute be unique?
    def self.attribute(name, options = {})
      @structure ||= {}
      @structure[name.to_sym] = {}
      # setup the schema
      @structure[name.to_sym][:class]   =
        options.key?(:class) ? options[:class] : Object
      @structure[name.to_sym][:format]  =
        options.key?(:format) ? options[:format] : nil
      @structure[name.to_sym][:validations] =
        options.key?(:validate) ? [*options[:validate]] : []
      @structure[name.to_sym][:unique] =
        options.key?(:unique) == true ? true : false
      @structure[name.to_sym][:index] =
        options.key?(:index) == true ? true : false
    end

    # This DSL method is used to setup the backend {StorageEngine} class and
    # optionally the {CacheProvider} for this Document type.
    #
    # @param storage_engine [Class] the {StorageEngine} child class to use
    # @option cache_opts [Class] :cache_provider (CacheProviders::LRUCache) the
    #   {CacheProvider} child class for caching
    # @option cache_opts [Fixnum] :cache_size the cache size, in terms of the
    #   number of objects stored
    # @raise [Exceptions::InvalidEngine] if the specified {StorageEngine} does
    #   not exist
    # @raise [Exceptions::InvalidCacheProvider] if a cache_provider is specified
    #   and it isn't a type of {CacheProvider}
    def self.engine(storage_engine, cache_opts = {})
      unless storage_engine.instance_of?(Class) &&
             storage_engine.ancestors.include?(StorageEngine)
        fail Exceptions::InvalidEngine
      end
      @engine = storage_engine
      if cache_opts.key?(:cache_provider)
        # Make sure the cache provider specified is valid
        unless cache_opts[:cache_provider].instance_of?(Class) &&
               cache_opts[:cache_provider].ancestors.include?(CacheProvider)
          fail Exceptions::InvalidCacheProvider
        end

        @engine.cache_provider(self, cache_opts[:cache_provider])
      end

      @engine.cache_size(
        self, cache_opts[:cache_size]
      ) if cache_opts.key?(:cache_size)
    end

    # @return [StorageEngine] a reference to the storage engine singleton of
    #   this document class
    def self.storage
      @engine ||= StorageEngines::YamlEngine
      @engine
    end

    # @return [StorageEngine] a reference to the storage engine singleton of
    #   this document class
    def storage
      self.class.send(:storage)
    end

    # @return [Hash] a copy of the schema information for this class
    def self.structure
      @structure ||= {}
      @structure.dup
    end

    # @return [Hash] a copy of the schema information for this class
    def structure
      self.class.send(:structure)
    end

    # Sets the maximum number of entries the cache instance for this document
    # will hold. Note: this clears the current contents of the cache.
    # @param size [Fixnum] the maximum size of this class' cache instance
    def self.cache_size(size)
      storage.cache_size(self, size)
    end

    # Allow direct access to the cache instance of this document class
    # @return [CacheProvider] this class' cache instance
    def self.cache
      storage.cache(self)
    end

    # Return all available instances of this type
    # @return [DocumentCollection] all documents of this type
    def self.all
      DocumentCollection.new(
        storage.all(self).collect { |doc_id| load(doc_id) },
        self
      )
    end

    # Query for Documents based on an attribute
    # @see DocumentCollection#where
    def self.where(attribute, value, comp_op = '==')
      if indexed_column?(attribute)
        DocumentCollection.new(
          storage.index_lookup(self, attribute, value, comp_op).collect do |did|
            load(did)
          end,
          self
        )
      else
        all.where(attribute, value, comp_op)
      end
    end

    # Compare two documents
    def <=>(other)
      id <=> other.id
    end

    # Should this column be indexed?
    # @return [Boolean]
    def self.indexed_column?(column)
      csym = column.to_sym
      structure.key?(csym) && structure[csym][:index] == true
    end

    def indexed_column?(column)
      self.class.send('indexed_column?'.to_sym, column)
    end

    # Uses the defined schema to setup getter and setter methods. Runs
    # validations, format checking, and type checking on setting methods.
    # @todo refactor and comment better
    # @raise [Exceptions::FailedValidation] if validation of an attribute fails
    #   while setting
    # @raise [Exceptions::InvalidInput] if, while setting, an attribute fails to
    #   conform to the type or format defined in the schema
    def method_missing(method, *args, &block)
      setter = method.to_s.match(/(.*)=$/) ? true : false
      key = setter ? $1.to_sym : method.to_s.to_sym

      if structure.key?(key) && setter
        if args.last.is_a?(structure[key][:class]) &&
           (
             structure[key][:format].nil? ||
             args.last.to_s.match(structure[key][:format])
           )
          valid = true
          if structure[key][:unique] == true
            fail Exceptions::NotUnique unless test_uniqueness(key, args.last)
          end
          structure[key][:validations].each do |validation|
            valid = send(validation.to_sym, args.last)
            fail Exceptions::FailedValidation unless valid
          end
          # here is where the lazy-loading happens
          refresh if @read_lock.synchronize { @lazy } &&
                     @read_lock.synchronize { committed? }
          @read_lock.synchronize do
            @write_lock.synchronize do
              if valid
                @data[key.to_s] = args.last
              end
            end
          end
          commit if indexed_column?(key) # indexed columns always cause commits
        else
          fail Exceptions::InvalidInput
        end
        @saved = false
      elsif structure.key?(key)
        # here is where the lazy-loading happens
        refresh if @read_lock.synchronize { @lazy } &&
                   @read_lock.synchronize { committed? }
        @read_lock.synchronize do
          @data[key.to_s]
        end
      else
        super
      end
    end

    def respond_to?(method)
      key = method.to_s.match(/(.*)=$/) ? $1.to_sym : method.to_s.to_sym

      if structure.key?(key)
        true
      else
        super
      end
    end

    private

    # check if a value is unique
    # @return [Boolean] is the value for this column unique?
    def test_uniqueness(column, value)
      if committed?
        (self.class.where(column.to_sym, value) - self).empty?
      else
        list = self.class.where(column.to_sym, value)
        if list.size == 1
          list.first.id == id
        else
          true
        end
      end
    end

  end
end
