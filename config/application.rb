require_relative "boot"

require "rails/all"

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module HanziTrail
  class Application < Rails::Application
    # Initialize configuration defaults for originally generated Rails version.
    config.load_defaults 8.1

    # Day-scoped features (streak, "reviewed today") must roll over at the
    # owner's local midnight, not UTC midnight.
    config.time_zone = "Europe/Istanbul"

    # No model attaches files (no has_one_attached anywhere in app/), so
    # variants are never generated. Disabling the processor keeps every
    # console and rake run from warning about the missing
    # image_processing gem.
    config.active_storage.variant_processor = :disabled

    # Tag every log line with the request id so one request stays one
    # grep in any environment (lograge renders the line, this labels it).
    config.log_tags = [ :request_id ]

    # Please, add to the `ignore` list any other `lib` subdirectories that do
    # not contain `.rb` files, or that should not be reloaded or eager loaded.
    # Common ones are `templates`, `generators`, or `middleware`, for example.
    config.autoload_lib(ignore: %w[assets tasks])

    # Configuration for the application, engines, and railties goes here.
    #
    # These settings can be overridden in specific environments using the files
    # in config/environments, which are processed later.
    #
    # config.time_zone = "Central Time (US & Canada)"
    # config.eager_load_paths << Rails.root.join("extras")
  end
end
