module RubyFFDB
  class Document

    def initialize(existing_id = false, lazy = true)
      if existing_id
        @document_id  = existing_id
        raise Exceptions::NoSuchDocument unless File.exists?(file_path)
        if lazy
          @lazy = true
        else
          reload(true)
          @lazy = false
        end
        @saved = true
      else
        @document_id = storage.next_id(self.class)
        @data = {}
        # relative to database root
        @saved = false
      end
    end

    def id
      @document_id
    end

    def file_path
      storage.file_path(self.class, @document_id)
    end

    def commit
      storage.store(self.class, @document_id, @data.dup) unless @saved
      @saved = true
    end

    alias_method :save, :commit

    def committed?
      return @saved
    end
    
    # Retrieve the stored data from disk, never using cache. Allows forcing to overwrite uncommitted changes.
    def reload(force = false)
      if committed? or force
        @data = storage.retrieve(self.class, @document_id, false)
      else
        raise Exceptions::PendingChanges
      end
      @saved = true
    end
    
    # Overwrites the document's data, either from disk or from cache. Useful for lazy-loading and not
    # typically used directly. Since data might have been pulled from cache, this can lead to bizarre
    # things if not used carefully and things rely on #committed? or @saved.
    def refresh
      @data = storage.retrieve(self.class, @document_id)
      @saved = true
    end
    
    def self.load(id)
      return self.new(id)
    end
    
    self.singleton_class.send(:alias_method, :get, :load)
    
    def self.attribute(name, options = {})
      @structure ||= {}
      @structure[name.to_sym] = {}
      # These aren't implemented yet...
      @structure[name.to_sym][:class]   = options.has_key?(:class) ? options[:class] : Object
      @structure[name.to_sym][:format]  = options.has_key?(:format) ? options[:format] : nil
      @structure[name.to_sym][:validations] = options.has_key?(:validate) ? [*options[:validate]] : []
    end
    
    # Set the StorageEngine class for this Document type
    def self.engine(storage_engine)
      raise Exceptions::InvalidEngine unless storage_engine.instance_of? Class and storage_engine.ancestors.include?(StorageEngine)
      @engine = storage_engine
    end
    
    def self.storage
      @engine ||= StorageEngines::YamlEngine
      @engine
    end
    
    def storage
      self.class.send(:storage)
    end
    
    def self.structure
      @structure ||= {}
      @structure.dup
    end
    
    def structure
      self.class.send(:structure)
    end
    
    def self.cache_size(size)
      storage.cache_size(self, size)
    end
    
    def self.cache
      storage.cache(self)
    end

    def method_missing(method, *args, &block)
      setter  = method.to_s.match(/.*=$/) ? true : false
      key     = setter ? method.to_s.match(/(.*)=$/)[1].to_sym : method.to_s.to_sym
      
      if structure.has_key?(key) and setter
        if args.last.kind_of? structure[key][:class] and (structure[key][:format].nil? or args.last.to_s.match structure[key][:format])
          valid = true
          structure[key][:validations].each do |validation|
            valid = self.send(validation.to_sym, args.last)
            raise Exceptions::FailedValidation unless valid
          end
          refresh if @lazy and committed? # here is where the lazy-loading happens
          @data[key.to_s] = args.last if valid
        else
          raise Exceptions::InvalidInput
        end
        @saved = false
      elsif structure.has_key?(key)
        refresh if @lazy and committed? # here is where the lazy-loading happens
        @data[key.to_s]
      else
        super
      end
    end

    def respond_to?(method)
      key = method.to_s.match(/.*=$/) ? method.to_s.match(/(.*)=$/)[1].to_sym : method.to_s.to_sym
      
      if structure.has_key?(key)
        true
      else
        super
      end
    end

  end
end