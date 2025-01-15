#!/bin/bash
#
# This script is called by the content pack creator ECS task. Its only purpose is to run the content
# pack service as we need a container with more memory than the jobs container to process map tiles.

# The content pack creator needs a web server running so Puppeteer can get airport snapshots
puma --config config/puma.rb &
WEB_SERVER_PID=$!

# Chromium/Puppeteer has problems with jemalloc; don't use it
export LD_PRELOAD=""

rails runner "ContentPacksCreator.new.create_content_packs"

# Kill the web server process once done (give it some time to gracefully exit and then sigkill it to ensure the ECS task stops)
kill $WEB_SERVER_PID
sleep 30
kill -9 $WEB_SERVER_PID
