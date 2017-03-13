module RFFDB
  module Exceptions
    class FailedValidation < RuntimeError
    end

    class InvalidEngine < RuntimeError
    end

    class InvalidInput < RuntimeError
    end

    class InvalidWhereQuery < RuntimeError
    end

    class NoSuchDocument < RuntimeError
    end

    class NotUnique < RuntimeError
    end

    class PendingChanges < RuntimeError
    end
  end
end
