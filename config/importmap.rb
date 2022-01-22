# Pin npm packages by running ./bin/importmap

pin "application", preload: true
pin_all_from Rails.root.join("app/assets/javascripts")

pin "@rails/ujs", to: "@rails--ujs.js" # @7.0.2
pin "mapbox-gl", to: "mapbox-gl.js"
pin "easymde", to: "easymde.min.js"
