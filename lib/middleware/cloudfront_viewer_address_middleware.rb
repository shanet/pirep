require 'ipaddr'

class CloudfrontViewerAddressMiddleware
  ORIGIN_SECRET_HEADER = 'HTTP_X_ORIGIN_SECRET'
  VIEWER_ADDRESS_HEADER = 'HTTP_CLOUDFRONT_VIEWER_ADDRESS'

  def initialize(app, origin_secret)
    @app = app
    @origin_secret = origin_secret

    # Don't refuse to boot without the secret since this is also built for tasks that don't serve requests (asset precompilation, migrations, etc.)
    Rails.logger.warn('Cloudfront origin secret not configured, requests that did not come through Cloudfront will not be rejected') if @origin_secret.blank?
  end

  def call(env)
    # Requests pass through Cloudfront and then API Gateway, which reports Cloudfront's IP as the client rather than the viewer's.
    # Cloudfront sends the viewer's address in a separate header so use that as the client IP instead. Cloudfront also adds a secret
    # header so requests that bypass it (by going to API Gateway directly) are rejected.
    origin_secret = env.delete(ORIGIN_SECRET_HEADER)
    return [403, {'content-type' => 'text/plain'}, ['Forbidden']] unless allowed_request?(env, origin_secret)

    viewer_ip = parse_viewer_ip(env[VIEWER_ADDRESS_HEADER])
    env['REMOTE_ADDR'] = viewer_ip if viewer_ip && trusted_origin_secret?(origin_secret)

    # Always remove the proxy headers so neither Rack nor Rails try to derive the client IP from them
    env.delete('HTTP_FORWARDED')
    env.delete('HTTP_X_FORWARDED_FOR')

    @app.call(env)
  end

private

  def allowed_request?(env, origin_secret)
    return true if @origin_secret.blank?

    # Allow the container's own health checks. REMOTE_ADDR is the socket's peer address so this can't be spoofed by a remote client.
    return true if loopback?(env['REMOTE_ADDR'])

    return trusted_origin_secret?(origin_secret)
  end

  def trusted_origin_secret?(origin_secret)
    return false if @origin_secret.blank? || origin_secret.blank?

    return ActiveSupport::SecurityUtils.secure_compare(origin_secret, @origin_secret)
  end

  def loopback?(ip)
    return IPAddr.new(ip).loopback?
  rescue IPAddr::Error
    return false
  end

  # The header is the viewer's IP and source port for both IPv4 and IPv6
  def parse_viewer_ip(viewer_address)
    return nil if viewer_address.blank?

    ip = viewer_address.rpartition(':').first
    IPAddr.new(ip)

    return ip
  rescue IPAddr::InvalidAddressError
    return nil
  end
end
