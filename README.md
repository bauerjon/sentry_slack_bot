# Sentry Slack Bot

No sentry slack notification left behind. 

***Note: In general, this gem is not super useful unless you already use https://sentry.io/integrations/slack/ to notify your slack room about sentry issue.***

### Available Features:

- Builds on top of https://sentry.io/integrations/slack/ to annoy people ***again*** if they were already notified about a sentry issue in slack and the team did nothing about it.
- Notifies slack room with a report around sentry issues that have been assigned in sentry, but neglected for over a week. This is helpful if people assign themselves in sentry, but never fix the issue.


### Configuration

```ruby
SentrySlackBot.configure do |config|
  config.sentry_token = ENV['YOUR_SENTRY_API_TOKEN'] # retrieved from https://sentry.io/api/
  config.slack_api_token = ENV['YOUR_SLACK_API_TOKEN'] # token from your app https://api.slack.com/slack-apps, needs permissions channels:history, channels:read, chat:write:bot, users:read, users:read.email
  config.slack_channel_id = ENV['SLACK_CHANNEL_TO_NOTIFY'] # i.e.- C0J97RLKB if you use https://sentry.io/integrations/slack/ use same channel id
  config.sentry_organization_slug = ENV['SENTRY_ORGANIZATION_NAME'] # slug for your sentry organization. https://sentry.io/<slug>/, required to grab list of projects
end
```

### Notify unattended issues

![screen shot 2018-05-31 at 4 50 15 pm](https://user-images.githubusercontent.com/5402488/40810831-a3a05c30-64f4-11e8-8e8e-470a81ead724.png)

#### Usage

```ruby
SentrySlackBot.notify_unattended_issues!
```

This will re-notify the team if a sentry issue was alerted in slack, but no action was taken in sentry. It looks at all issues messages in slack from sentry and if the issue is still unresolved, unassigned, or unignored in sentry it will re-notify the team. 

By default it will notify `@channel`.  To send notify project's issues to certain groups/individuals you can set this value in config:


```ruby
SentrySlackBot.configure do |config|
  ...
  config.slack_group_per_project = {
    'ember-app' => '@bugs-ember',
    'rails-app' => '@bugs-rails',
    'jacks-service' => '@jack'
  }
  ...
end
```


#### Notify stale assignments

```ruby
SentrySlackBot.notify_stale_assignments!
```


#### Where/When to call it

When and where these commands are called is up to you. We've used it in a sidekiq worker using scheduled sidekiq jobs.

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

```ruby
Sidekiq.configure_server do |config|
  config.periodic do |mgr|
    mgr.register('0 15 * * *', UnattendedIssuesWorker) # https://crontab.guru/#0_3_*_*_*
  end
end
```
