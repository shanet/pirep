# This script is called by the content pack creator ECS task. Its only purpose is to run the content
# pack service as we need a container with more memory than the jobs container to process map tiles.
ContentPacksCreator.new.create_content_packs
