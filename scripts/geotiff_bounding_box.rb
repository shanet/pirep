#!/usr/bin/env ruby
#
# Usage: ./geotiff_bounding_box.rb path/to/geotiff.tif

require 'json'

ARGV.each_with_index do |file, index|
  info = JSON.parse(`gdalinfo -json "#{file}"`)

  coordinates = {
    max_latitude: -1000,
    min_latitude: 1000,
    max_longitude: -1000,
    min_longitude: 1000,
  }

  info['wgs84Extent']['coordinates'].first.each do |coordinate|
    coordinates[:max_latitude] = [coordinates[:max_latitude], coordinate.last].max
    coordinates[:min_latitude] = [coordinates[:min_latitude], coordinate.last].min

    coordinates[:max_longitude] = [coordinates[:max_longitude], coordinate.first].max
    coordinates[:min_longitude] = [coordinates[:min_longitude], coordinate.first].min
  end

  puts "#{info['description']}: [#{coordinates[:min_longitude]}, #{coordinates[:min_latitude]}, #{coordinates[:max_longitude]}, #{coordinates[:max_latitude]}],"
end
