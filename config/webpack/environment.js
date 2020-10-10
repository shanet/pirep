const { environment } = require('@rails/webpacker')

module.exports = environment

environment.loaders.delete('nodeModules')
