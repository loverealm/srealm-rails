require File.expand_path('../boot', __FILE__)

# Pick the frameworks you want:
require 'active_model/railtie'
require 'active_job/railtie'
require 'active_record/railtie'
require 'action_controller/railtie'
require 'action_mailer/railtie'
require 'action_view/railtie'
require 'sprockets/railtie'
require 'rails/all'
require 'net/http'
require 'yaml'
require './lib/ext/string'
require './lib/ext/hash'
require './lib/ext/array'
require './lib/ext/action_controller_parameters'
require './lib/redirect_outgoing_mails'

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module Loverealm
  class Application < Rails::Application
    # Settings in config/environments/* take precedence over those specified here.
    # Application configuration should go into files in config/initializers
    # -- all .rb files in that directory are automatically loaded.

    # Set Time.zone default to the specified zone and make Active Record auto-convert to this zone.
    # Run "rake -D time" for a list of tasks for finding time zone names. Default is UTC.
    # config.time_zone = 'Central Time (US & Canada)'

    # The default locale is :en and all translations from config/locales/*.rb,yml are auto loaded.
    # config.i18n.load_path += Dir[Rails.root.join('my', 'locales', '*.{rb,yml}').to_s]
    # config.i18n.default_locale = :de
    config.generators do |g|
      g.factory_girl false
    end
    config.active_record.raise_in_transactional_callbacks = true

    config.action_dispatch.perform_deep_munge = false

    # Bower config
    config.assets.paths << Rails.root.join('vendor', 'assets', 'components')
    Dir[Rails.root.join("config", "routes", "*.rb")].each{|r| routes_reloader.paths.unshift(r) }
    # config.paths["config/routes"] += Dir[Rails.root.join('config/routes/*.rb')]

    config.paperclip_defaults = {
        storage: :s3,
        s3_host_name: "s3-eu-west-1.amazonaws.com",
        s3_protocol: :https,
        s3_credentials: File.join(Rails.root, 'config', 's3.yml')
    }

    config.autoload_paths += %W(
      #{config.root}/app/services/bot
      #{config.root}/app/services
      #{config.root}/app/jobs
      #{config.root}/lib
    )
    ActionMailer::Base.register_interceptor(RedirectOutgoingMails)
  end
end
