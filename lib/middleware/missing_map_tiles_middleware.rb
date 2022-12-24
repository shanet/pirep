class MissingMapTilesMiddleware
  def initialize(app)
    @app = app
  end

  def call(env)
    # We want to return a 204 for any tiles that are missing since this is much faster for map rendering than a 404
    # In production this is handled by the CDN so this middleware is only needed in development
    if env['PATH_INFO'].start_with?('/assets/tiles') && !Rails.public_path.join(env['PATH_INFO']).exist?
      return [204, {}, '']
    end

    @app.call(env)
  end
end
