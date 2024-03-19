require 'test_helper'

class AirportSearcherTest < ActiveSupport::TestCase
  setup do
    @airport1 = create(:airport)
    @airport2 = create(:airport)
  end

  test 'is empty?' do
    assert AirportSearcher.new({}).empty?, 'Airport searcher not empty with no filters given'
    assert AirportSearcher.new({distance_from: 0}).empty?, 'Airport searcher not empty with some filters given'
  end

  test 'is not empty?' do
    assert_not AirportSearcher.new({tag_food: '1'}).empty?, 'Airport searcher empty with filters given'
    assert_not AirportSearcher.new({distance_from: 1}).empty?, 'Airport searcher empty with filters given'
    assert_not AirportSearcher.new({airport_from: 'KPAE'}).empty?, 'Airport searcher empty with filters given'
  end

  test 'no filters given' do
    assert_nil AirportSearcher.new({}).results, 'Not nil when given no filters'
  end

  test 'filters everything' do
    @airport1.update!(landing_rights: :restricted)
    create(:tag, airport: @airport1, name: :airpark)
    create(:metar, airport: @airport1, flight_category: 'MVFR')
    create(:event, airport: @airport1, start_date: 3.days.from_now, end_date: 4.days.from_now)

    filters = {
      airport_from: @airport1.code,
      distance_from: 10,
      elevation: 10_000,
      runway_length: 1,
      events_threshold: 30,
      weather_mvfr: true,
      access_restricted: true,
      tag_airpark: '1',
    }

    assert_equal [@airport1].to_set, AirportSearcher.new(filters).results.to_set, 'Wrong search results with all filters'
  end

  test 'filters location with invalid airport' do
    assert_raises(Exceptions::AirportNotFound) do
      AirportSearcher.new({airport_from: 'KXXX', distance_from: 42}).results
    end
  end

  test 'filters location with incomplete inputs' do
    assert_raises(Exceptions::IncompleteLocationFilter) do
      AirportSearcher.new({airport_from: @airport1.code}).results
    end

    assert_raises(Exceptions::IncompleteLocationFilter) do
      AirportSearcher.new({distance_from: 42}).results
    end
  end

  test 'filters location' do
    @airport1.update!(coordinates: [46, -120])

    assert_equal [@airport2], AirportSearcher.new({airport_from: @airport2.code, distance_from: 5}).results, 'Unexpected location filtering'

    # Order matters here; the closest airport should be first
    assert_equal [@airport2, @airport1], AirportSearcher.new({airport_from: @airport2.icao_code, distance_from: 500}).results, 'Unexpected location filtering'
  end

  test 'filters access' do
    @airport2.update!(landing_rights: :private_)

    assert_equal [@airport1].to_set, AirportSearcher.new({access_public: true}).results.to_set, 'Unexpected airport access filtering'
  end

  test 'filters any tags' do
    create(:tag, airport: @airport1, name: :food)
    create(:tag, airport: @airport1, name: :webcam)
    create(:tag, airport: @airport2, name: :camping)

    assert_equal [@airport1, @airport2].to_set, AirportSearcher.new({tags_match: :or, tag_food: '1', tag_camping: '1'}).results.to_set, 'Unexpected airport any tags filtering'
  end

  test 'filters all tags' do
    create(:tag, airport: @airport1, name: :food)
    create(:tag, airport: @airport1, name: :webcam)
    create(:tag, airport: @airport2, name: :food)

    assert_equal [@airport1].to_set, AirportSearcher.new({tags_match: :and, tag_food: '1', tag_webcam: '1'}).results.to_set, 'Unexpected airport all tags filtering'
  end

  test 'filters elevation' do
    @airport1.update!(elevation: 1_000)
    @airport2.update!(elevation: 1_001)

    assert_equal [@airport1].to_set, AirportSearcher.new({elevation: 1000}).results.to_set, 'Unexpected airport elevation filtering'
  end

  test 'filters runways' do
    @airport1.runways.destroy_all
    @airport2.runways.destroy_all

    create(:runway, airport: @airport1, length: 9_999, surface: 'ASPH', lights: 'LOW')
    create(:runway, airport: @airport2, length: 9_999, surface: 'GRASS', lights: nil)
    create(:runway, airport: @airport2, length: 10_000, surface: 'GRASS', lights: nil)

    assert_equal [@airport2].to_set, AirportSearcher.new({runway_length: 10_000}).results.to_set, 'Unexpected airport runway length filtering'
    assert_equal [@airport1].to_set, AirportSearcher.new({runway_paved: true}).results.to_set, 'Unexpected airport runway paved filtering'
    assert_equal [@airport2].to_set, AirportSearcher.new({runway_grass: true}).results.to_set, 'Unexpected airport runway grass filtering'
    assert_equal [@airport1].to_set, AirportSearcher.new({runway_lighted: true}).results.to_set, 'Unexpected airport runway lighting filtering'
  end

  test 'filters weather' do
    create(:metar, airport: @airport1, flight_category: 'VFR')
    create(:metar, airport: @airport2, flight_category: 'IFR')

    assert_equal [@airport1].to_set, AirportSearcher.new({weather_vfr: true}).results.to_set, 'Unexpected airport VFR weather filtering'
    assert_equal [@airport2].to_set, AirportSearcher.new({weather_ifr: true}).results.to_set, 'Unexpected airport IFR weather filtering'
    assert_equal [@airport1, @airport2].to_set, AirportSearcher.new({weather_vfr: true, weather_ifr: true}).results.to_set, 'Unexpected airport VFR & IFR weather filtering'
  end

  test 'filters facility type' do
    heliport = create(:airport, facility_type: :heliport)
    assert_equal [heliport].to_set, AirportSearcher.new({facility_heliport: true}).results.to_set, 'Unexpected facility type filtering'

    # It should filter out non-airports when the facility type is otherwise not specified
    assert_equal [@airport1, @airport2].to_set, AirportSearcher.new({runway_length: 1}).results.to_set, 'Unexpected facility type filtering'
  end

  test 'filters events' do
    create(:event, airport: @airport1, start_date: 29.days.from_now, end_date: 30.days.from_now)
    create(:event, airport: @airport2, start_date: 31.days.from_now, end_date: 32.days.from_now)

    assert_equal [@airport1].to_set, AirportSearcher.new({events_threshold: 30}).results.to_set, 'Unexpected airport upcoming events filtering'
    assert_equal [@airport1, @airport2].to_set, AirportSearcher.new({events_threshold: 60}).results.to_set, 'Unexpected airport upcoming events filtering'
  end
end
