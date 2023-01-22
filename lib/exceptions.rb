module Exceptions
  class AirportDatabaseDownloadFailed < StandardError; end
  class ChartDownloadFailed < StandardError; end
  class ChartTilesGenerationFailed < StandardError; end
  class ChartUploadFailed < StandardError; end
  class DiagramUploadFailed < StandardError; end
  class FaaDataImporterTaskFailed < StandardError; end
  class GdalBinaryNotFound < StandardError; end
  class MaxmindDatabaseChecksumDownloadFailed < StandardError; end
  class MaxmindDatabaseDownloadFailed < StandardError; end
  class MaxmindDatabaseIntegrityCheckFailed < StandardError; end
  class OpenStreetMapsQueryFailed < StandardError; end
  class UnknownChartType < StandardError; end
  class UnknownFaaProductType < StandardError; end
end
