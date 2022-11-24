module Exceptions
  class AirportDatabaseDownloadFailed < StandardError; end
  class ChartTilesGenerationFailed < StandardError; end
  class GdalBinaryNotFound < StandardError; end
  class MaxmindDatabaseChecksumDownloadFailed < StandardError; end
  class MaxmindDatabaseDownloadFailed < StandardError; end
  class MaxmindDatabaseIntegrityCheckFailed < StandardError; end
  class OpenStreetMapsQueryFailed < StandardError; end
  class ChartDownloadFailed < StandardError; end
  class UnknownChartType < StandardError; end
end
