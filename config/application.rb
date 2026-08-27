require_relative "boot"

require "rails"
# Pick the frameworks you want:
require "active_model/railtie"
require "active_job/railtie"
require "active_record/railtie"
require "active_storage/engine"
require "action_controller/railtie"
require "action_mailer/railtie"
# require "action_mailbox/engine"
# require "action_text/engine"
require "action_view/railtie"
require "action_cable/engine"
require "rails/test_unit/railtie"

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module FflDraft
  class Application < Rails::Application
    # Initialize configuration defaults for originally generated Rails version.
    config.load_defaults 8.1

    # Please, add to the `ignore` list any other `lib` subdirectories that do
    # not contain `.rb` files, or that should not be reloaded or eager loaded.
    # Common ones are `templates`, `generators`, or `middleware`, for example.
    config.autoload_lib(ignore: %w[assets tasks])

    # Configuration for the application, engines, and railties goes here.
    #
    # These settings can be overridden in specific environments using the files
    # in config/environments, which are processed later.
    #
    config.time_zone = "Eastern Time (US & Canada)"
    # Fallback for portraits whose variant has not been generated yet, and for the local
    # disk service. Keeps image URLs stable across Turbo frame replacements instead of
    # redirecting browsers to short-lived signed URLs.
    config.active_storage.resolve_model_to_route = :rails_storage_proxy

    # Portraits are served straight from the CDN when this is set, which keeps a cold draft
    # room from spending a Puma thread per image proxying bytes out of S3. Unset falls back
    # to the proxy route above, so the app works with no CDN in front of it.
    config.x.cdn_host = ENV["CDN_HOST"].presence
    # config.eager_load_paths << Rails.root.join("extras")

    # Don't generate system test files.
    config.generators.system_tests = nil
  end
end
