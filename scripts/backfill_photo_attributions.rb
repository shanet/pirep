#!/usr/bin/env ruby
# rubocop:disable all

# Usage: rails runner script/backfill_photo_attributions.rb [BATCH_SIZE]
#
# This script re-downloads photos from Google Places API to capture attributions.
# Run it multiple times to process all airports in batches to avoid excessive API charges.

batch_size = (ARGV[0] || 10).to_i

puts "Backfilling photo attributions for airports"
puts "Batch size: #{batch_size}"
puts "-" * 80

# Find airports with cached external photos that don't have google_photo_reference metadata
# (this indicates they were cached before we started saving attribution data)
airport_ids_needing_backfill = Airport.joins(external_photos_attachments: :blob)
  .where.not(external_photos_updated_at: nil)
  .where("active_storage_blobs.metadata NOT LIKE '%google_photo_reference%'")
  .pluck(:id)
  .uniq

airports_needing_backfill = Airport.where(id: airport_ids_needing_backfill)

total_airports = airports_needing_backfill.count
puts "Found #{total_airports} airport(s) with photos needing attribution backfill"

if total_airports.zero?
  puts "No airports to process!"
  exit 0
end

# Process in batches
airports_to_process = airports_needing_backfill.take(batch_size)
puts "Processing #{airports_to_process.count} airport(s) in this batch"
puts

processed = []
skipped = []

airports_to_process.each_with_index do |airport, index|
  puts "[#{index + 1}/#{airports_to_process.count}] Processing #{airport.code} - #{airport.name}"

  begin
    # Clear the cache timestamp and fetch fresh photos with new metadata
    airport.update!(external_photos_updated_at: nil)
    photos = airport.uncached_external_photos(force_update: true)

    if !photos || photos.empty?
      puts "  No photos found, skipping"
      skipped << {airport: airport, reason: 'No photos found'}
      next
    end

    puts "  Found #{photos.count} photo(s), cache job enqueued"
    processed << airport
  rescue => error
    puts "  ERROR: #{error.message}"
    skipped << {airport: airport, reason: error.message}
  end

  puts
end

puts "-" * 80
puts "Summary:"
puts "  Processed: #{processed.count}"
puts "  Skipped: #{skipped.count}"
puts "  Remaining: #{[total_airports - batch_size, 0].max}"
puts

if processed.any?
  puts "Updated airports:"

  processed.each do |airport|
    puts "  - #{airport.code} (#{airport.name})"
  end

  puts
end

if skipped.any?
  puts "Skipped airports:"

  skipped.each do |item|
    puts "  - #{item[:airport].code} (#{item[:airport].name}): #{item[:reason]}"
  end

  puts
end

puts "Run this script again to process more airports"
