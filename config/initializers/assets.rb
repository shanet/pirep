# Version of your assets, change this if you want to expire all your assets.
Rails.application.config.assets.version = '1.0'

# Add additional assets to the asset load path
Rails.application.config.assets.paths += [
  Rails.root.join('vendor/fonts/fontawesome'),
  Rails.root.join('vendor/javascript'),
  Rails.root.join('vendor/stylesheets'),
]
