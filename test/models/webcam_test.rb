require 'test_helper'

class WebcamTest < ActiveSupport::TestCase
  test 'is image URL' do
    assert create(:webcam).image?, 'Webcam URL not a direct image link'
    assert_not create(:webcam, url: 'https://example.com/webcam').image?, 'Webcam URL a direct image link'
    assert_not create(:webcam, url: 'https://example.com/webcam.html').image?, 'Webcam URL a direct image link'
    assert_not create(:webcam, url: 'http://example.com/webcam.jpg').image?, 'HTTP Webcam URL a direct image link'
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
