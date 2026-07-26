source "https://rubygems.org"

gem "bootsnap", "~> 1.24", ">= 1.24.6", require: false
gem "dartsass-rails", "~> 0.5.1"
gem "importmap-rails", "~> 2.2", ">= 2.2.3"
gem "jbuilder", "~> 2.15", ">= 2.15.1"
gem "kamal", "~> 2.11", require: false
gem "pg", "~> 1.6", ">= 1.6.3"
gem "propshaft", "~> 1.3", ">= 1.3.2"
gem "puma", "~> 8.0", ">= 8.0.2"
gem "rails", "~> 8.1.3"
gem "solid_cable", "~> 4.0"
gem "solid_cache", "~> 1.0", ">= 1.0.10"
gem "solid_queue", "~> 1.5"
gem "stimulus-rails", "~> 1.3", ">= 1.3.4"
gem "thruster", "~> 0.1.21", require: false
gem "turbo-rails", "~> 2.0", ">= 2.0.23"
gem "tzinfo-data", "~> 1.2026", ">= 1.2026.2", platforms: %i[ windows jruby ]
gem "view_component", "~> 4"

group :development, :test do
  gem "debug", platforms: %i[ mri windows ], require: "debug/prelude"
  gem "bundler-audit", require: false
  gem "brakeman", require: false
  gem "rubocop-rails-omakase", require: false
  gem "rails-controller-testing"
end

group :development do
  gem "web-console"
  gem "dockerfile-rails"
end

group :test do
  gem "capybara"
  gem "selenium-webdriver"
  gem "simplecov", "1.0.0.rc3", require: false
end
