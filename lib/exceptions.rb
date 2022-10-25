module Exceptions
  class AirportDatabaseDownloadFailed < StandardError; end
  class MaxmindDatabaseChecksumDownloadFailed < StandardError; end
  class MaxmindDatabaseDownloadFailed < StandardError; end
  class MaxmindDatabaseIntegrityCheckFailed < StandardError; end
  class OpenStreetMapsQueryFailed < StandardError; end
end
