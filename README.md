# Sentry Slack Bot

Notifies slack room with sentry reports around stale assignments, and works in tandem with https://sentry.io/integrations/slack/ to annoy people in a thread when people haven't acknowledged issues.


### Usage

```ruby
SentrySlackBot.configure do |config|
  config.sentry_token = ENV['YOUR_SENTRY_API_TOKEN'] # retrieved from https://sentry.io/api/
  config.slack_api_token = ENV['YOUR_SLACK_API_TOKEN'] # token from your app https://api.slack.com/slack-apps, needs permissions channels:history, channels:read, chat:write:bot, users:read, users:read.email
  config.slack_channel_id = ENV['SLACK_CHANNEL_TO_NOTIFY'] # i.e.- C0J97RLKB if you use https://sentry.io/integrations/slack/ use same channel id
  config.sentry_organization_slug = ENV['SENTRY_ORGANIZATION_NAME'] # slug for your sentry organization. https://sentry.io/<slug>/, required to grab list of projects
end
```

### Where/When to call it

When and where this command is called is up to you. We've run it in a sidekiq worker using scheduled sidekiq jobs.

```ruby
class UnattendedIssuesWorker
  include Sidekiq::Worker

  def perform
    return unless valid_business_hours? # optional, we found it helpful to NOT notify ourselves continuously unless in office
    SentrySlackBot.notify_slack_of_unattended_issues!
  end
  
  private
  
  def valid_business_hours?
    true
  end
end
```
