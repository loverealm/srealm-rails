# Be sure to restart your server when you modify this file.

# Version of your assets, change this if you want to expire all your assets.
Rails.application.config.assets.version = '1.0'
Rails.application.config.assets.precompile += %w( admin_manifest.css admin_manifest.js )
Rails.application.config.assets.precompile += %w( libraries/twitterfontana/manifest.css )
Rails.application.config.assets.precompile += %w( libraries/twitterfontana/manifest.js )
Rails.application.config.assets.precompile += %w( .svg .eot .woff .woff2 .ttf )


# Precompile additional assets.
# application.js, application.css, and all non-JS/CSS in app/assets folder are already added.
