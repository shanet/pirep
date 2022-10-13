module Exceptions
  class StandardContextError < StandardError
    def initialize(context=nil, *args)
      @__raven_context = {extra: context}
      super(*args)
    end
  end

  class AirportDatabaseDownloadFailed < StandardContextError; end
  class OpenStreeMapsQueryFailed < StandardContextError; end
end
