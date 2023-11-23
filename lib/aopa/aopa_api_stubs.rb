module AopaApiStubs
  def self.stub_requests(api_host)
    WebMock.stub_request(:post, api_host).to_return(body: Rails.root.join('test/fixtures/aopa/events.json').read)

    WebMock.enable!
  end
end
