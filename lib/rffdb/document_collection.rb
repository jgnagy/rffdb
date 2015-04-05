module RubyFFDB
  class DocumentCollection
    include Enumerable

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
        @list.collect { |item|
          item if item.send(attribute).send(comparison_method.to_sym, value)
        }.compact,
        @type
      )
    end
  end
end
