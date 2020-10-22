# Version of your assets, change this if you want to expire all your assets.
Rails.application.config.assets.version = '1.0'

# Add additional assets to the asset load path
Rails.application.config.assets.paths += [
  Rails.root.join('node_modules'),
  Rails.root.join('vendor', 'stylesheets'),
]

Rails.configuration.assets.precompile += [
  'mapbox.css',
]
