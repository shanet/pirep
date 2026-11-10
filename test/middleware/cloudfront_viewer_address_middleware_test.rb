require 'test_helper'
require Rails.root.join('lib/middleware/cloudfront_viewer_address_middleware')

class CloudfrontViewerAddressMiddlewareTest < ActiveSupport::TestCase
  ORIGIN_SECRET = 'secret'
  CLOUDFRONT_IP = '10.10.10.1'
  REMOTE_IP = '8.8.4.4'
  VIEWER_IP = '8.8.8.8'

  test 'uses viewer IPv4 address with valid origin secret' do
    status, env = call_middleware(origin_secret: ORIGIN_SECRET, viewer_address: "#{VIEWER_IP}:46532")

    assert_equal 200, status
    assert_equal VIEWER_IP, remote_ip(env)
    assert_equal VIEWER_IP, Rack::Request.new(env).ip
    assert_nil env['HTTP_FORWARDED']
    assert_nil env['HTTP_X_FORWARDED_FOR']
  end

  test 'uses viewer IPv6 address with valid origin secret' do
    _status, env = call_middleware(origin_secret: ORIGIN_SECRET, viewer_address: '2001:db8::1:46532')
    assert_equal '2001:db8::1', remote_ip(env)
  end

  test 'uses remote address with valid origin secret and invalid viewer address' do
    status, env = call_middleware(origin_secret: ORIGIN_SECRET, viewer_address: 'garbage')

    assert_equal 200, status
    assert_equal REMOTE_IP, remote_ip(env)
  end

  test 'rejects request without origin secret' do
    status, env = call_middleware(origin_secret: nil, viewer_address: "#{VIEWER_IP}:46532")

    assert_equal 403, status
    assert_nil env, 'Request was passed to app'
  end

  test 'rejects request with incorrect origin secret' do
    status, env = call_middleware(origin_secret: 'wrong', viewer_address: "#{VIEWER_IP}:46532")

    assert_equal 403, status
    assert_nil env, 'Request was passed to app'
  end

  test 'allows loopback request without origin secret' do
    ['127.0.0.1', '::1'].each do |loopback_ip|
      status, env = call_middleware(origin_secret: nil, viewer_address: "#{VIEWER_IP}:46532", remote_ip: loopback_ip)

      assert_equal 200, status
      assert_equal loopback_ip, remote_ip(env)
      assert_nil env['HTTP_FORWARDED']
      assert_nil env['HTTP_X_FORWARDED_FOR']
    end
  end

  test 'allows request when origin secret is not configured' do
    status, env = call_middleware(origin_secret: nil, viewer_address: "#{VIEWER_IP}:46532", configured_secret: nil)

    assert_equal 200, status
    assert_equal REMOTE_IP, remote_ip(env)
  end

  test 'removes origin secret header' do
    _status, env = call_middleware(origin_secret: ORIGIN_SECRET, viewer_address: "#{VIEWER_IP}:46532")
    assert_nil env[CloudfrontViewerAddressMiddleware::ORIGIN_SECRET_HEADER]
  end

private

  # Simulate a request from Cloudfront through API Gateway which reports Cloudfront as the client. Returns the response status and the env
  # that was passed to the app (nil if the request was rejected before reaching it).
  def call_middleware(origin_secret:, viewer_address:, configured_secret: ORIGIN_SECRET, remote_ip: REMOTE_IP)
    headers = {
      'REMOTE_ADDR' => remote_ip,
      'HTTP_FORWARDED' => "for=#{CLOUDFRONT_IP};proto=https",
      'HTTP_X_FORWARDED_FOR' => CLOUDFRONT_IP,
      CloudfrontViewerAddressMiddleware::VIEWER_ADDRESS_HEADER => viewer_address,
    }

    headers[CloudfrontViewerAddressMiddleware::ORIGIN_SECRET_HEADER] = origin_secret if origin_secret

    app_env = nil
    app = ->(env) {app_env = env; [200, {}, ['']]}

    status, _headers, _body = CloudfrontViewerAddressMiddleware.new(ActionDispatch::RemoteIp.new(app), configured_secret).call(Rack::MockRequest.env_for('/', headers))
    return [status, app_env]
  end

  def remote_ip(env)
    return ActionDispatch::Request.new(env).remote_ip
  end
end
