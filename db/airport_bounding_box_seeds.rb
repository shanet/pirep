class AirportBoundingBoxSeeds
  def initialize
    @bounding_boxes = YAML.safe_load(Rails.root.join('db/fixtures/airport_bounding_boxes.yml').read)
  end

  def calculate(airport)
    bounding_box = {
      southwest: {latitude: nil, longitude: nil},
      northeast: {latitude: nil, longitude: nil},
    }

    raw_bounding_box = @bounding_boxes[airport.code]
    return bounding_box unless raw_bounding_box

    bounding_box[:southwest][:latitude] = raw_bounding_box[2]
    bounding_box[:southwest][:longitude] = raw_bounding_box[3]
    bounding_box[:northeast][:latitude] = raw_bounding_box[0]
    bounding_box[:northeast][:longitude] = raw_bounding_box[1]

    return bounding_box
  end
end
