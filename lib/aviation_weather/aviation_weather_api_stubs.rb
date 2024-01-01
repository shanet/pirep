module AviationWeatherApiStubs
  def self.stub_requests
    WebMock.stub_request(:get, /https:\/\/aviationweather\.gov\/data\/cache\/metars\.cache\.xml\.gz/)
      .to_return(body: Rails.root.join('test/fixtures/aviation_weather/metars.xml.gz').read)

    WebMock.stub_request(:get, /https:\/\/aviationweather\.gov\/data\/cache\/tafs\.cache\.xml\.gz/)
      .to_return(body: Rails.root.join('test/fixtures/aviation_weather/tafs.xml.gz').read)

    WebMock.enable!
  end
end
