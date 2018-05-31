# Sentry Slack Bot

No sentry slack notification left behind. 

***Note: In general, this gem is not super useful unless you already use https://sentry.io/integrations/slack/ to notify your slack room about sentry issues. This gem does not notify slack about new sentry issues, since that is already solved in the existing slack app, but offers a tool to re-notify teams about forgotten sentry issues/assignments.***

### Available Features:

- Builds on top of https://sentry.io/integrations/slack/ to annoy people ***again*** if they were already notified about a sentry issue in slack and the team did nothing about it.

    ![screen shot 2018-05-31 at 4 50 15 pm](https://user-images.githubusercontent.com/5402488/40811598-799f4182-64f7-11e8-9c3f-e5064a826971.png)
- Notifies slack room with a report around sentry issues that have been assigned in sentry, but neglected for over a week. This is helpful if people assign themselves in sentry, but never fix the issue.

    ![screen shot 2018-05-31 at 5 18 04 pm](https://user-images.githubusercontent.com/5402488/40811890-c751f14e-64f8-11e8-9bfb-9a51b05a2a24.png)



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

#### Usage

```ruby
SentrySlackBot.notify_unattended_issues!
```

This will re-notify the team if a sentry issue was alerted in slack, but no action was taken in sentry. It looks at all issue messages in slack and if the issue is still unresolved, unassigned, or unignored in sentry it will re-notify the team. 

By default it will notify `@channel`.  To notify certain groups/individuals you can set this value in config per sentry project:
 

```ruby
SentrySlackBot.configure do |config|
  ...
  config.slack_group_per_sentry_project = {
    'ember-app' => '@bugs-ember',
    'rails-app' => '@bugs-rails',
    'jacks-service' => '@jack'
  }
  ...
end
```

By default it will look at messages that came in after 5/31/2018. If you want the bot to look at messages before or after that date you can override it in the config:

```ruby
SentrySlackBot.configure do |config|
  ...
  config.unattended_issue_cut_off_date = '2018-01-01'
  ...
end
```

#### Notify stale assignments

```ruby
SentrySlackBot.notify_stale_assignments!
```

This will notify the slack channel with a message telling the team who hasn't resolved/ignored/commented issues they have been assigned to or not commented on in over 7 days. To change the grace period of updating an issue, you can change this value in the config:

```ruby
SentrySlackBot.configure do |config|
  ...
  config.stale_assignment_grace_period = 14.days # default is 7.days
  ...
end
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
