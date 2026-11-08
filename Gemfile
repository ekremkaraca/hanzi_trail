# frozen_string_literal: true

source 'https://rubygems.org'

gem 'action_policy'
gem 'aws-sdk-s3', require: false # R2 is S3-compatible; card audio storage
gem 'bcrypt', '~> 3.1'
gem 'bootsnap', '~> 1.24', '>= 1.24.6', require: false
gem 'faraday', '>= 2.15', require: false
gem 'importmap-rails', '~> 2.2', '>= 2.2.3'
gem 'jbuilder', '~> 2.15', '>= 2.15.1'
gem 'kamal', '~> 2.11', require: false
gem 'lograge', '>= 0.15.1'
gem 'pg', '~> 1.6', '>= 1.6.3'
gem 'propshaft', '~> 1.3', '>= 1.3.2'
gem 'puma', '~> 8.0', '>= 8.0.2'
gem 'rails', '~> 8.1.3'
gem 'solid_cable', '~> 4.0'
gem 'solid_cache', '~> 1.0', '>= 1.0.10'
gem 'solid_queue', '~> 1.7'
gem 'stimulus-rails', '~> 1.3', '>= 1.3.4'
gem 'thruster', '~> 0.1.21', require: false
gem 'turbo-rails', '~> 2.0', '>= 2.0.23'
gem 'tzinfo-data', '~> 1.2026', '>= 1.2026.2', platforms: %i[windows jruby]
gem 'view_component', '~> 4'

group :development, :test do
  gem 'brakeman', require: false
  gem 'bundler-audit', require: false
  gem 'debug', platforms: %i[mri windows], require: 'debug/prelude'
  gem 'rails-controller-testing'
  gem 'rubocop-rails', '>= 2.38', require: false
end

group :development do
  gem 'dockerfile-rails'
  gem 'web-console'
end

group :test do
  gem 'capybara'
  gem 'rexml' # SSML well-formedness assertions (no longer bundled transitively)
  gem 'selenium-webdriver'
  gem 'simplecov', '~> 1.1', require: false
end
