module FaaApiStubs
  def self.stub_requests
    WebMock.stub_request(:get, /https:\/\/nfdc\.faa\.gov\/webContent\/28DaySub\/extra\/.+_APT_CSV\.zip/)
      .to_return(body: Rails.root.join('test/fixtures/faa/airport_data.zip').read)

    WebMock.stub_request(:get, /https:\/\/aeronav\.faa\.gov\/upload_313-d\/terminal\/DDTPP[a-eA-E]_.+\.zip/)
      .to_return(body: Rails.root.join('test/fixtures/faa/airport_diagrams.zip').read)

    WebMock.stub_request(:get, /https:\/\/aeronav\.faa\.gov\/visual\/.+\/.+\/.+/)
      .to_return(body: Rails.root.join('test/fixtures/faa/charts_test.zip').read)

    WebMock.enable!
  end
end
