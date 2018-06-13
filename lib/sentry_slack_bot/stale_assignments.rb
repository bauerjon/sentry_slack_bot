module SentrySlackBot
  class StaleAssignments
    def self.notify!
      self.new.notify!
    end

    def notify!
      stale_issues_by_assignee = Hash.new{|h,k| h[k]=[]}

      assigned_unresolved_sentry_issues.each do |issue|
        issue_details = issue_details_from_id(issue['id'])

        if stale_assignment?(issue_details) && !recent_comments?(issue_details)
          stale_issues_by_assignee[issue_details['assignedTo']['email']] << issue_details['permalink']
        end
      end

      message_text = "The following unresolved issues have been assigned to you for over 1 week without resolve or additional comments. Please comment on issue with any updates/fix the issue/'ingore until X'/resolve/unassign. Otherwise you will continue to be notified during business hours.\n\n"

      stale_issues_by_assignee.each do |email, issue_links|
        name = get_slack_name_from_email(email) || email
        message_text += "#{name}:\n\n#{issue_links.join("\n")}\n\n"
      end

      send_message_to_channel(SentrySlackBot::Config.slack_channel_id, message_text)
    end

    private

    def assigned_unresolved_sentry_issues
      @assigned_unresolved_sentry_issues ||= (
        headers = { "Authorization" => "Bearer #{SentrySlackBot::Config.sentry_api_token}" }
        sentry_projects.flat_map do |project|
          response = HTTParty.get("https://app.getsentry.com/api/0/projects/#{SentrySlackBot::Config.sentry_organization_slug}/#{project['slug']}/issues/?query=is:unresolved is:assigned", headers: headers)
          JSON.parse(response.body)
        end
      )
    end

    def stale_assignment?(issue)
      date = issue['activity'].find{|a| a['type'] == 'assigned'}['dateCreated']
      DateTime.parse(date) < (Time.now - SentrySlackBot::Config.stale_assignment_grace_period)
    end

    def recent_comments?(issue)
      note = issue['activity'].find{|a| a['type'] == 'note'}

      if note && note['dateCreated']
        DateTime.parse(note['dateCreated']) > (Time.now - SentrySlackBot::Config.stale_assignment_grace_period)
      else
        false
      end
    end

    def issue_details_from_id(issue_id)
      headers = { "Authorization" => "Bearer #{SentrySlackBot::Config.sentry_api_token}" }
      response = HTTParty.get("https://app.getsentry.com/api/0/issues/#{issue_id}/", headers: headers)
      JSON.parse(response.body)
    end

    def sentry_projects
      headers = { "Authorization" => "Bearer #{SentrySlackBot::Config.sentry_api_token}" }
      response = HTTParty.get("https://app.getsentry.com//api/0/organizations/#{SentrySlackBot::Config.sentry_organization_slug}/projects/", headers: headers)
      JSON.parse(response.body)
    end

    def get_slack_name_from_email(email)
      response = HTTParty.get("https://slack.com/api/users.lookupByEmail?email=#{email}&token=#{SentrySlackBot::Config.slack_api_token}")
      slack_name = JSON.parse(response.body).dig('user','name')
      slack_name ? "@#{slack_name}" : nil
    end

    def send_message_to_channel(channel, text)
      response = HTTParty.post("https://slack.com/api/chat.postMessage?token=#{SentrySlackBot::Config.slack_api_token}&channel=#{channel}&text=#{URI.encode(text)}&as_user=false&link_names=1")
      JSON.parse(response.body)
    end
  end
end
