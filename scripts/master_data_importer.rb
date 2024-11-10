# This script is called by the importer ECS task. Its only purpose is to run the importer
# service as we need a container with more memory than the jobs container to process map tiles.
MasterDataImporter.new.import!
