module OpenStreetMapsApiStubs
  def self.stub_requests(api_host)
    WebMock.stub_request(:post, api_host).to_return(body: {
      # Stub data take from Sullivan Lake, 09S
      elements: [
        {type: 'node', id: 2_688_856_823, lat: 48.8382765, lon: -117.2840137},
        {type: 'node', id: 2_688_856_842, lat: 48.8436501, lon: -117.2839675},
        {
          type: 'way',
          id: 263_267_824,
          nodes: [2_688_856_842, 2_688_856_823],
          tags: {
            aeroway: 'runway',
            length: '538',
            ref: '16/34',
            surface: 'grass',
            width: '30',
          },
        },
      ],
    }.to_json)

    WebMock.enable!
  end
end
