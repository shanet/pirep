require 'application_system_test_case'

class ContentPacksTest < ApplicationSystemTestCase
  test 'creates content packs' do
    # Set the port the web server is running on in the test process for the content pack creator to pass to Puppeteer
    ENV['PORT'] = Capybara.current_session.server.port.to_s

    expectations = {}

    # Create airports in the past so their updated timestamps are old and the content pack creator treats them as cached
    travel_to(5.minutes.ago) do
      airport_food = create(:airport, tags: [create(:tag, name: :food), create(:tag, name: :lodging)])
      airport_lodging = create(:airport, tags: [create(:tag, name: :lodging)])
      airport_camping = create(:airport, tags: [create(:tag, name: :camping)])
      airport_car = create(:airport, tags: [create(:tag, name: :car)])
      airport_golfing = create(:airport, tags: [create(:tag, name: :golfing)])

      expectations = {
        all_airports: {count: 5, airports: [airport_food, airport_lodging, airport_camping, airport_car, airport_golfing]},
        restaurants: {count: 1, airports: [airport_food]},
        lodging: {count: 2, airports: [airport_food, airport_lodging]},
        camping: {count: 1, airports: [airport_camping, airport_golfing]},
        cars: {count: 1, airports: [airport_car]},
        golfing: {count: 1, airports: [airport_golfing]},
      }
    end

    # Delete any lingering cached airport info PDFs from a previous test run
    FileUtils.rm_rf(ContentPacksCreator.cache)

    freeze_time do
      # Create an old content pack to assert it was deleted by the content pack creation process
      old_content_pack = File.join(ContentPacksCreator.directory, 'foo.zip')
      FileUtils.mkdir_p(File.dirname(old_content_pack))
      FileUtils.touch(old_content_pack)

      report = ContentPacksCreator.new.create_content_packs

      # All old files should be deleted after creating new content packs
      assert_not File.exist?(old_content_pack), "Did not delete old content packs data at #{old_content_pack}"

      # All airport info PDFs should be freshly rendered but should still only be done once for the first content pack only
      expected_airports = expectations.reduce([]) {|airports, expectation| airports << expectation.last[:airports]}
      assert_airports_rendered expected_airports.flatten.uniq.count, report, 'Re-rendered airports instead of using cache'

      ContentPacksCreator::CONTENT_PACKS.each do |content_pack_id, content_pack_configuration|
        path = ContentPacksCreator.path_for_content_pack(content_pack_id)
        assert File.exist?(path), "Archive for content pack #{content_pack_id} does not exist"

        Zip::File.open(path) do |archive|
          # Assert the manifest and KML files exist
          assert archive.glob('**/manifest.json').first, "Manifest file for content pack #{content_pack_id} does not exist"
          assert archive.glob("**/Pirep - #{content_pack_configuration[:name]}.kml").first, "KML file for content pack #{content_pack_id} does not exist"

          assert_equal expectations[content_pack_id][:count], archive.glob('**/*.pdf').count, "Unexpected airport info PDF count for content pack #{content_pack_id}"

          # Every airport should have an info PDF
          expectations[content_pack_id][:airports].each do |airport|
            assert archive.glob("**/#{airport.code} Info.pdf"), "Airport info PDF for airport #{airport.code} not in content pack #{content_pack_id}"
          end

          kml = Nokogiri::XML(archive.glob("**/Pirep - #{content_pack_configuration[:name]}.kml").first.get_input_stream.read)
          namespaces = {'kml' => 'http://www.opengis.net/kml/2.2'}

          # There should be a style icon for each content pack in the KML
          ContentPacksCreator::CONTENT_PACKS.keys do |_content_pack|
            kml.xpath("//kml:Style[@id=\"#{content_pack_id}_icon\"]", namespaces)
          end

          # Each airport should be in the KML
          assert_equal expectations[content_pack_id][:count], kml.xpath('//kml:Placemark', namespaces).count, "Unexpected airport in KML for content pack #{content_pack_id}"

          kml.xpath('//kml:description', namespaces).each_with_index do |airport_description, index|
            assert airport_description.text.include?(expectations[content_pack_id][:airports][index].code), "Airport not in KML for content pack #{content_pack_id}"
          end
        end

        assert ContentPacksCreator.content_pack_file_size(content_pack_id) > 0, "Invalid file size for content pack #{content_pack_id}"
        assert_in_delta Time.zone.now, ContentPacksCreator.content_pack_updated_at(content_pack_id), 1.second, "Invalid content pack #{content_pack_id} updated at timestamp"
      end
    end

    # Creating content packs again should use cached PDFs
    report = ContentPacksCreator.new.create_content_packs
    assert_airports_rendered 0, report, 'Re-rendered airports instead of using cache'

    # Updating one airport should bust its cache
    expectations[:all_airports][:airports].first.update! description: 'foobar'

    travel_to(5.minutes.from_now) do
      report = ContentPacksCreator.new.create_content_packs
      assert_airports_rendered 1, report, 'Did not bust cache of updated airport'
    end
  end

private

  def assert_airports_rendered(expected, report, message)
    airports_rendered = report.reduce(0) {|accumulator, content_pack| accumulator + content_pack.last[:airports_rendered]}
    assert_equal expected, airports_rendered, message
  end
end
