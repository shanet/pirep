class AirportCompletionProgressCalculator
  ANNOTATIONS = :annotations
  LANDING_REQUIREMENTS = :landing_requirements
  LANDING_RIGHTS = :landing_rights
  PHOTOS = :photos
  TAGS = :tags
  TEXTAREA_CREW_CAR = :crew_car
  TEXTAREA_DESCRIPTION = :description
  TEXTAREA_FLYING_CLUBS = :flying_clubs
  TEXTAREA_FUEL_LOCATION = :fuel_location
  TEXTAREA_LANDING_FEES = :landing_fees
  TEXTAREA_TRANSIENT_PARKING = :transient_parking
  TEXTAREA_WIFI = :wifi
  WEBCAMS = :webcams

  CONFIGURATION = {
    ANNOTATIONS => {value: 10, label: 'Airport map annotations'},
    LANDING_REQUIREMENTS => {value: 10},
    LANDING_RIGHTS => {value: 10},
    PHOTOS => {value: 10, label: 'Airport photos'},
    TAGS => {value: 10, label: 'Tags'},
    TEXTAREA_CREW_CAR => {value: 10, label: 'Crew car availability'},
    TEXTAREA_DESCRIPTION => {value: 30, label: 'General description'},
    TEXTAREA_FLYING_CLUBS => {value: 10, label: 'Local flying clubs'},
    TEXTAREA_FUEL_LOCATION => {value: 10, label: 'Fuel pump location'},
    TEXTAREA_LANDING_FEES => {value: 10, label: 'Landing &amp; tie-down fees'},
    TEXTAREA_TRANSIENT_PARKING => {value: 10, label: 'Transient parking location'},
    TEXTAREA_WIFI => {value: 10, label: 'WiFi availability'},
    WEBCAMS => {value: 10, label: 'Webcam links'},
  }

  FEATURED_THRESHOLD = 100 # percent

  def initialize(airport)
    @airport = airport
  end

  def featured?
    return (percent_complete >= FEATURED_THRESHOLD)
  end

  def percent_complete
    percent = present_information.reduce(0) do |accumulator, item|
      accumulator + CONFIGURATION[item][:value]
    end

    return [percent, 100].min
  end

  def missing_information
    info = present_information
    missing_information = {}

    CONFIGURATION.each do |key, value|
      missing_information[key] = value[:label] if info.exclude?(key) && value[:label]
    end

    return missing_information
  end

private

  def present_information
    textareas = Airport::TEXTAREA_EDITABLE_COLUMNS.keys.map do |column|
      (@airport.send(column).present? ? column : nil)
    end

    return (textareas + [
      (Tag.addable_tags.keys.intersect?(@airport.tags.pluck(:name).map(&:to_sym)) ? TAGS : nil),
      (@airport.contributed_photos.any? ? PHOTOS : nil),
      (@airport.annotations&.any? ? ANNOTATIONS : nil),
      (@airport.webcams.any? ? WEBCAMS : nil),
      (@airport.landing_rights == :restricted ? LANDING_RIGHTS : nil),
      (@airport.landing_requirements.present? ? LANDING_REQUIREMENTS : nil),
    ]).compact
  end
end
