$LOAD_PATH.unshift File.expand_path('../../lib', __FILE__)
require 'sentry_slack_bot'
require 'pry'
require 'webmock/rspec'

SentrySlackBot::Config.configure do |config|
  config.sentry_api_token = 'test_sentry_token'
  config.slack_api_token = 'test_slack_token'
  config.slack_channel_id = 'C0J93RMKB'
  config.sentry_organization_slug = 'sentry-project-lf'
  config.slack_group_per_sentry_project = {
    'ember-app' => '@bugs-ember',
    'rails-app' => '@bugs-rails'
  }
end
