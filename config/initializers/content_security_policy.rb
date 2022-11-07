# Rails-ujs will apply a nonce value to any inline JavaScript
Rails.configuration.content_security_policy_nonce_generator = ->(_request) {SecureRandom.base64(32)}
Rails.configuration.content_security_policy_nonce_directives = ['script-src']

Rails.configuration.content_security_policy do |policy|
  # All hosts that are allowed to load content onto the pages
  hosts = [
    Rails.configuration.asset_host.presence || :self,
    'api.mapbox.com',
    'events.mapbox.com',
    'sentry.io',
  ]

  policy.base_uri(:self)
  policy.connect_src(*(hosts + [:self]))
  policy.default_src(*(hosts + [:self]))
  policy.font_src(*hosts)
  policy.form_action(:self)
  policy.img_src(*(hosts + [:data]))
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
