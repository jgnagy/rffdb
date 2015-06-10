module RubyFFDB
  class DocumentCollection
    include Enumerable
    include Comparable

    # @return [Class] this is a collection of this {Document} subclass
    attr_reader :type

    # @param list [#to_a] the list of Documents to reference
    # @param type [Class] the type of Document this collection references
    def initialize(list, type = Document)
      @list = list.to_a
      @type = type
    end

    # Iterates over the list of Document instances
    def each(&block)
      @list.each(&block)
    end

    # Returns the number of Document instances in the collection
    # @return [Fixnum]
    def size
      @list.size
    end

    # Return the first item in the collection
    # @return [Document] the first item in the collection
    def first
      @list.first
    end

    # Return the last item in the collection
    # @return [Document] the last item in the collection
    def last
      @list.last
    end

    # Return the collection item at the specified index
    # @return [Document,DocumentCollection] the item at the requested index
    def [](index)
      if index.is_a?(Range)
        self.class.new(@list[index], @type)
      else
        @list[index]
      end
    end

    # Return a collection after subtracting from the original
    # @return [DocumentCollection]
    def -(other)
      new_list = @list.dup
      if other.respond_to?(:to_a)
        other.to_a.each do |item|
          new_list.delete_if { |document| document.id == item.id }
        end
      elsif other.is_a?(@type)
        new_list.delete_if { |document| document.id == other.id }
      else
        fail Exceptions::InvalidInput
      end
      self.class.new(new_list, @type)
    end

    # Return a collection after adding to the original
    #   Warning: this may cause duplicates or mixed type joins! For safety,
    #   use #merge
    # @return [DocumentCollection]
    def +(other)
      if other.respond_to?(:to_a)
        self.class.new(@list + other.to_a, @type)
      elsif other.is_a?(@type)
        self.class.new(@list + [other], @type)
      else
        fail Exceptions::InvalidInput
      end
    end

    # Merge two collections
    # @return [DocumentCollection]
    def merge(other)
      if other.is_a?(self.class) && other.type == @type
        new_list = []

        new_keys = collect(&:id)
        new_keys += other.collect(&:id)

        new_keys.sort.uniq.each do |doc_id|
          new_list << self.class.get(doc_id)
        end

        self.class.new(new_list, @type)
      else
        fail Exceptions::InvalidInput
      end
    end

    # Allow comparison of collection
    # @return [Boolean] do the collections contain the same document ids?
    def ==(other)
      if other.is_a? self.class
        collect(&:id).sort == other.collect(&:id).sort
      else
        false
      end
    end

    # Does the collection contain anything?
    # @return [Boolean]
    def empty?
      @list.empty?
    end

    # Allow complex sorting like an Array
    # @return [DocumentCollection] sorted collection
    def sort(&block)
      self.class.new(super(&block), @type)
    end

    # Horribly inefficient way to allow querying Documents by their attributes.
    # This method can be chained for multiple / more specific queries.
    #
    # @param attribute [Symbol] the attribute to query
    # @param value [Object] the value to compare against
    # @param comparison_method [String,Symbol] the method to use for comparison
    #   - allowed options are "'==', '>', '>=', '<', '<=', and 'match'"
    # @raise [Exceptions::InvalidWhereQuery] if not the right kind of comparison
    # @return [DocumentCollection]
    def where(attribute, value, comparison_method = '==')
      valid_comparison_methods = [:'==', :'>', :'>=', :'<', :'<=', :match]
      unless valid_comparison_methods.include?(comparison_method.to_sym)
        fail Exceptions::InvalidWhereQuery
      end
      self.class.new(
        @list.collect do |item|
          item if item.send(attribute).send(comparison_method.to_sym, value)
        end.compact,
        @type
      )
    end
  end
end
