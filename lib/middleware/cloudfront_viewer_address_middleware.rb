require 'ipaddr'

class CloudfrontViewerAddressMiddleware
  ORIGIN_SECRET_HEADER = 'HTTP_X_ORIGIN_SECRET'
  VIEWER_ADDRESS_HEADER = 'HTTP_CLOUDFRONT_VIEWER_ADDRESS'

  def initialize(app, origin_secret)
    @app = app
    @origin_secret = origin_secret
  end

  def call(env)
    # Requests pass through Cloudfront and then API Gateway, which reports Cloudfront's IP as the client rather than the viewer's.
    # Cloudfront sends the viewer's address in a separate header so use that as the client IP instead. It's only trusted when the
    # request also has the secret header that Cloudfront adds.
    origin_secret = env.delete(ORIGIN_SECRET_HEADER)
    viewer_ip = parse_viewer_ip(env[VIEWER_ADDRESS_HEADER])

    env['REMOTE_ADDR'] = viewer_ip if viewer_ip && trusted_origin_secret?(origin_secret)

    # Always remove the proxy headers so neither Rack nor Rails try to derive the client IP from them. Requests without a valid secret
    # didn't come through Cloudfront so these headers can't be trusted either.
    env.delete('HTTP_FORWARDED')
    env.delete('HTTP_X_FORWARDED_FOR')

    @app.call(env)
  end

private

  def trusted_origin_secret?(origin_secret)
    return false if @origin_secret.blank? || origin_secret.blank?

    return ActiveSupport::SecurityUtils.secure_compare(origin_secret, @origin_secret)
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
