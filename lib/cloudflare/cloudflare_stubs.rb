module CloudflareStubs
  def self.stub_requests
    WebMock.stub_request(:post, 'https://challenges.cloudflare.com/turnstile/v0/siteverify').to_return(lambda {|request|
      # Always pass unless the Cloudflare constant to always fail was set as the secret key
      next {body: {'success' => request.body.exclude?(Cloudflare::TURNSTILE_FAILING)}.to_json}
    })

    WebMock.enable!
  end
end
