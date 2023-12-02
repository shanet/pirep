module Exceptions
  class AirportDatabaseDownloadFailed < StandardError; end
  class AopaEventsFetchFailed < StandardError; end
  class ChartDownloadFailed < StandardError; end
  class ChartTilesGenerationFailed < StandardError; end
  class ChartUploadFailed < StandardError; end
  class DatabaseBackupFailed < StandardError; end
  class DiagramUploadFailed < StandardError; end
  class EaaEventsFetchFailed < StandardError; end
  class GdalBinaryNotFound < StandardError; end
  class GooglePhotosQueryFailed < StandardError; end
  class GoogleTimezoneQueryFailed < StandardError; end
  class MasterDataImporterTaskFailed < StandardError; end
  class MaxmindDatabaseChecksumDownloadFailed < StandardError; end
  class MaxmindDatabaseDownloadFailed < StandardError; end
  class MaxmindDatabaseIntegrityCheckFailed < StandardError; end
  class OpenStreetMapsQueryFailed < StandardError; end
  class UnknownChartType < StandardError; end
  class UnknownFaaProductType < StandardError; end
end
