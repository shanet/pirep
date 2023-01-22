require 'exceptions'
require 'open_street_maps/open_street_maps_api'

class AirportBoundingBoxCalculator
  def initialize
    @open_street_maps = OpenStreetMapsApi.client
  end

  def calculate(airport)
    response = @open_street_maps.bounding_box(airport.latitude, airport.longitude)

    parsed_response = parse_ways(response[:elements])
    parse_nodes(response[:elements], parsed_response)

    return calculate_bounding_box(parsed_response)
  rescue Exceptions::OpenStreetMapsQueryFailed
    Rails.logger.warn "Bounding box query failed for #{airport.code}"
    return empty_bounding_box
  end

private

  def parse_ways(elements)
    ways = {}

    # Extract all of the ways in the response and build a set of the nodes that comprise it
    elements.each do |element|
      next unless element[:type] == 'way'

      ways[element[:id]] = element.merge(nodes: [], node_ids: element[:nodes].to_set)
    end

    return ways
  end

  def parse_nodes(elements, ways)
    # Add each node to its respective way
    elements.each do |element|
      next unless element[:type] == 'node'

      ways.each do |_id, way|
        way[:nodes] << element if way[:node_ids].include?(element[:id])
      end
    end
  end

  def calculate_bounding_box(ways)
    bounding_box = empty_bounding_box

    ways.each do |_id, way|
      way[:nodes].each do |node|
        bounding_box[:southwest][:latitude] = [bounding_box[:southwest][:latitude] || node[:lat], node[:lat]].min
        bounding_box[:southwest][:longitude] = [bounding_box[:southwest][:longitude] || node[:lon], node[:lon]].min

        bounding_box[:northeast][:latitude] = [bounding_box[:northeast][:latitude] || node[:lat], node[:lat]].max
        bounding_box[:northeast][:longitude] = [bounding_box[:northeast][:longitude] || node[:lon], node[:lon]].max
      end
    end

    return bounding_box
  end

  def empty_bounding_box
    return {
      southwest: {latitude: nil, longitude: nil},
      northeast: {latitude: nil, longitude: nil},
    }
  end
end
