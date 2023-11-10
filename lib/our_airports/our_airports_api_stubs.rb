module OurAirportsApiStubs
  def self.stub_requests
    ['airports', 'runways', 'regions'].each do |dataset|
      WebMock.stub_request(:get, /https:\/\/davidmegginson.github.io\/ourairports-data\/#{dataset}.csv/)
        .to_return(body: Rails.root.join("test/fixtures/our_airports/#{dataset}.csv").read)
    end

    WebMock.enable!
  end
end
