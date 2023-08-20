# Rails-ujs will apply a nonce value to any inline JavaScript
Rails.configuration.content_security_policy_nonce_generator = ->(_request) {SecureRandom.base64(32)}
Rails.configuration.content_security_policy_nonce_directives = ['script-src', 'style-src']

Rails.configuration.content_security_policy do |policy|
  # All hosts that are allowed to load content onto the pages
  hosts = [
    Rails.configuration.action_controller.asset_host.presence&.gsub('https://', '') || :self,
    Rails.configuration.try(:tiles_host).presence&.gsub('https://', ''), # rubocop:disable Rails/SafeNavigation
    'api.mapbox.com',
    'events.mapbox.com',
    'sentry.io',
  ].compact

  policy.base_uri(:self)
  policy.child_src(:blob)
  policy.connect_src(*(hosts + ['*.ingest.sentry.io', :self]))
  policy.default_src(*(hosts + [:self]))
  policy.font_src(*hosts)
  policy.form_action(:self)
  policy.img_src(*(hosts + ['www.gravatar.com', '*.googleusercontent.com', :data, :self]))
  policy.object_src(:none)
  policy.script_src(*hosts)
  policy.style_src(*hosts)
  policy.worker_src(:blob)

  # Send any CSP errors to Sentry
  if Rails.application.credentials.sentry_dsn_frontend
    public_key, secret_key, project_id = Rails.application.credentials.sentry_dsn_frontend.match(/https?:\/\/(.+)@(.+).ingest.sentry.io\/(.+)/).captures
    policy.report_uri("https://#{secret_key}.ingest.sentry.io/api/#{project_id}/security/?sentry_key=#{public_key}")
  end
end
