require 'test_helper'

class WebcamTest < ActiveSupport::TestCase
  test 'adds webcam tag to airport' do
    airport = create(:airport)
    assert airport.tags.where(name: :webcam).empty?, 'Airport already has webcam tag'

    assert_enqueued_with(job: AirportGeojsonDumperJob) do
      create(:webcam, airport: airport)
    end

    assert airport.tags.where(name: :webcam).any?, 'Webcam tag not added to airport'
  end

  test 'removes webcam tag from airport' do
    airport = create(:airport)
    webcam1 = create(:webcam, airport: airport)
    webcam2 = create(:webcam, airport: airport)

    # The webcam tags should only be removed when the last webcam on the airport is deleted
    webcam1.destroy!
    assert airport.tags.where(name: :webcam).any?, 'Webcam tag removed from airport'

    assert_enqueued_with(job: AirportGeojsonDumperJob) do
      webcam2.destroy!
      assert airport.tags.where(name: :webcam).empty?, 'Webcam tag not removed from airport'
    end
  end

  test 'disallows duplicate URLs on airport' do
    airport = create(:airport)
    create(:webcam, airport: airport, url: 'example.com')

    assert_raises(ActiveRecord::RecordInvalid) do
      create(:webcam, airport: airport, url: 'example.com')
    end

    assert create(:webcam, url: 'example.com').valid?, 'Webcam on different airport invalid'
  end

  test 'is image URL' do
    assert create(:webcam).image?, 'Webcam URL not a direct image link'
    assert_not create(:webcam, url: 'https://example.com/webcam').image?, 'Webcam URL a direct image link'
    assert_not create(:webcam, url: 'https://example.com/webcam.html').image?, 'Webcam URL a direct image link'
    assert_not create(:webcam, url: 'http://example.com/webcam.jpg').image?, 'HTTP Webcam URL a direct image link'
  end

  test 'is frame URL' do
    assert create(:webcam, :frame).frame?, 'Webcam URL not a frame URL'
    assert_not create(:webcam).frame?, 'Webcam URL a frame URL'
    assert_not create(:webcam, url: 'https://example.com/webcam').frame?, 'Webcam URL a frame URL'
  end

  test 'is embedded' do
    assert create(:webcam).embedded?, 'Image webcam not embedded'
    assert create(:webcam, :frame).embedded?, 'Frame webcam not embedded'
    assert_not create(:webcam, url: 'https://example.com').embedded?, 'URL webcam not embedded'
  end

  test 'adds URL protocol if missing' do
    assert create(:webcam, url: 'example.com').url.start_with?('https://'), 'Protocol not added to webcam URL'
    assert create(:webcam, url: 'http://example.com').url.start_with?('http://'), 'Protocol malformed on webcam URL'
  end

  test 'allows valid URLs' do
    webcam = create(:webcam)

    [
      webcam.url,
      'example.com',
      'https://example.com',
      'http://example.com',
      'subdomain.example.com',
      'subdomain.example.com/webcam',
      'subdomain.example.com/webcam/image.png',
      'subdomain.example.com/webcam/image',
      'example.com:8080',
      'subdomain.some-example.com',
    ].each do |url|
      webcam.url = url
      assert webcam.valid?, "Webcam not valid with valid URL: #{url}"
    end
  end

  test 'rejects invalid URLs' do
    webcam = create(:webcam)

    [
      'example',
      'ftp://example.com',
      'invalid_host.com',
      'foo@example.com',
      '/assets/image.jpg',
      '../path/traversal',
      'javascript:alert(1)',
      'data:foobar',
    ].each do |url|
      webcam.url = url
      assert_not webcam.valid?, "Webcam valid with invalid URL: #{url}"
    end
  end
end
