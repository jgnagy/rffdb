module RubyFFDB
  module Exceptions
    class FailedValidation < Exception
    end

    class InvalidEngine < Exception
    end

    class InvalidInput < Exception
    end

    class InvalidWhereQuery < Exception
    end

    class NoSuchDocument < Exception
    end

    class NotUnique < Exception
    end

    class PendingChanges < Exception
    end
  end
end
