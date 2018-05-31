# Sentry Slack Bot

Notifies slack room with sentry reports around stale assignments, and works in tandem with https://sentry.io/integrations/slack/ to annoy people in a thread when people haven't acknowledged issues.


### Usage

```ruby
config = {
  sentry_token: ENV['YOUR_SENTRY_API_TOKEN'], # retrieved from https://sentry.io/api/
  slack_api_token: ENV['YOUR_SLACK_API_TOKEN'], # token from your app https://api.slack.com/slack-apps, needs permissions channels:history, channels:read, chat:write:bot, users:read, users:read.email
  slack_channel_id: ENV['SLACK_CHANNEL_TO_NOTIFY'], # i.e.- C0J97RLKB if you use https://sentry.io/integrations/slack/ use same channel id
}
```

### Where/When to call it
