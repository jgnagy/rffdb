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
      if index.kind_of?(Range)
        self.class.new(@list[index], @type)
      else
        @list[index]
      end
    end
  end
end