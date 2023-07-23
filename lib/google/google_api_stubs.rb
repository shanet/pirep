module GoogleApiStubs
  def self.stub_requests(api_host)
    WebMock.stub_request(:get, /#{api_host}\/findplacefromtext\/json\?.+/).to_return(lambda {|request|
      # Extract the given location so the distance radius check passes
      matches = request.uri.query.match(/.*locationbias=circle:\d+@(-?\d+.\d+),(-?\d+.\d+)/)

      next {
        body: {
          candidates: [
            {place_id: 1, geometry: {location: {lat: 1000, lng: -1000}}}, # Invalid, should be filtered out by distance radius check
            {place_id: 2, geometry: {location: {lat: matches[1].to_f, lng: matches[2].to_f}}},
          ],
        }.to_json,
      }
    })

    WebMock.stub_request(:get, /#{api_host}\/details\/json\?.+/).to_return(lambda {|request|
      # Extract the place ID
      matches = request.uri.query.match(/.*place_id=(.+),?/)

      # The invalid place ID from above (ID = 1) should have been filtered out. If not requested with that ID then something is wrong.
      unless matches[1] == '2'
        next {body: {result: {}}.to_json}
      end

      next {
        body: {
          result: {
            photos: [
              {photo_reference: 1, html_attribution: ['Google Place Photos API key not set, using fallback image']},
              {photo_reference: 2, html_attribution: ['Google Place Photos API key not set, using fallback image']},
            ],
          },
        }.to_json,
      }
    })

    WebMock.stub_request(:get, /#{api_host}\/photo\?.+/).to_return(lambda {|request|
      # Extract the photo reference ID in order to return two different photos (this should match a value in the stubbed request above)
      matches = request.uri.query.match(/.*photoreference=(.+),?/)

      next {
        headers: {
          location: "/images/placeholder_#{matches[1]}.jpg",
        },
        status: 302,
      }
    })

    WebMock.enable!
  end
end
