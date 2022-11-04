class FetchAirportBoundingBoxJob < ApplicationJob
  def perform(airport)
    bounding_box = AirportBoundingBoxCalculator.new.calculate(airport)

    airport.update!({
      bbox_checked: true,
      bbox_ne_latitude: bounding_box[:northeast][:latitude],
      bbox_ne_longitude: bounding_box[:northeast][:longitude],
      bbox_sw_latitude: bounding_box[:southwest][:latitude],
      bbox_sw_longitude: bounding_box[:southwest][:longitude],
    })
  end
end
