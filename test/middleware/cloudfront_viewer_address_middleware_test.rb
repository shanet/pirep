require 'test_helper'
require Rails.root.join('lib/middleware/cloudfront_viewer_address_middleware')

class CloudfrontViewerAddressMiddlewareTest < ActiveSupport::TestCase
  ORIGIN_SECRET = 'secret'
  CLOUDFRONT_IP = '10.10.10.1'
  VIEWER_IP = '8.8.8.8'

  test 'uses viewer IPv4 address with valid origin secret' do
    env = call_middleware(origin_secret: ORIGIN_SECRET, viewer_address: "#{VIEWER_IP}:46532")

    assert_equal VIEWER_IP, remote_ip(env)
    assert_equal VIEWER_IP, Rack::Request.new(env).ip
    assert_nil env['HTTP_FORWARDED']
    assert_nil env['HTTP_X_FORWARDED_FOR']
  end

  test 'uses viewer IPv6 address with valid origin secret' do
    env = call_middleware(origin_secret: ORIGIN_SECRET, viewer_address: '2001:db8::1:46532')
    assert_equal '2001:db8::1', remote_ip(env)
  end

  test 'ignores viewer address without origin secret' do
    env = call_middleware(origin_secret: nil, viewer_address: "#{VIEWER_IP}:46532")
    assert_equal CLOUDFRONT_IP, remote_ip(env)
  end

  test 'ignores viewer address with incorrect origin secret' do
    env = call_middleware(origin_secret: 'wrong', viewer_address: "#{VIEWER_IP}:46532")
    assert_equal CLOUDFRONT_IP, remote_ip(env)
  end

  test 'ignores viewer address when origin secret is not configured' do
    env = call_middleware(origin_secret: '', viewer_address: "#{VIEWER_IP}:46532", configured_secret: nil)
    assert_equal CLOUDFRONT_IP, remote_ip(env)
  end

  test 'ignores invalid viewer address' do
    env = call_middleware(origin_secret: ORIGIN_SECRET, viewer_address: 'garbage')
    assert_equal CLOUDFRONT_IP, remote_ip(env)
  end

  test 'removes origin secret header' do
    env = call_middleware(origin_secret: ORIGIN_SECRET, viewer_address: "#{VIEWER_IP}:46532")
    assert_nil env[CloudfrontViewerAddressMiddleware::ORIGIN_SECRET_HEADER]
  end

private

  # Simulate a request from Cloudfront through API Gateway which connects from a private VPC address and reports Cloudfront as the client
  def call_middleware(origin_secret:, viewer_address:, configured_secret: ORIGIN_SECRET)
    headers = {
      'REMOTE_ADDR' => '8.8.4.4',
      'HTTP_FORWARDED' => "for=#{CLOUDFRONT_IP};proto=https",
      'HTTP_X_FORWARDED_FOR' => CLOUDFRONT_IP,
      CloudfrontViewerAddressMiddleware::VIEWER_ADDRESS_HEADER => viewer_address,
    }

    headers[CloudfrontViewerAddressMiddleware::ORIGIN_SECRET_HEADER] = origin_secret if origin_secret

    app_env = nil
    app = ->(env) {app_env = env; [200, {}, ['']]}

    CloudfrontViewerAddressMiddleware.new(ActionDispatch::RemoteIp.new(app), configured_secret).call(Rack::MockRequest.env_for('/', headers))
    return app_env
  end

  def remote_ip(env)
    return ActionDispatch::Request.new(env).remote_ip
  end
end
