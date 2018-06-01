module SentrySlackBot
  class UnattendedIssues
    class << self
      def notify!
        slack_channels_messages.each do |message|
          title_link = message.try(:[], 'attachments')&.first.try(:[], 'title_link')

          if title_link
            match_data = /.*issues\/(?<issue_id>.*)\/.*/.match(title_link)
            next unless match_data
            issue = issue_from_id(match_data['issue_id'])

            if issue && issue['assignedTo'] == nil
              ts = message['ts']
              group_to_notify = SentrySlackBot::Config.slack_group_per_sentry_project[issue['project']['slug']]
              text = "Hey there #{group_to_notify}! This bug is unresolved and has not been assigned in Sentry. *Please assign/resolve/or 'Ignore until happens X times...'*\n If left unassigned/unresolved/unignored you will continue to receive notifications during business hours."
              send_message_to_thread(ts, text)
            end
          end
        end
      end

      def issue_from_id(issue_id)
        unassigned_unresolved_sentry_issues.find{|a| a['id'] == issue_id}
      end

      def unassigned_unresolved_sentry_issues
        @unassigned_unresolved_sentry_issues ||= (
          headers = { "Authorization" => "Bearer #{SentrySlackBot::Config.sentry_api_token}" }
          poppays_sentry_projects.flat_map do |project|
            response = HTTParty.get("https://app.getsentry.com/api/0/projects/popular-pays-lf/#{project['slug']}/issues/?statsPeriod=14d&query=is:unresolved is:unassigned", headers: headers)
            JSON.parse(response.body)
          end
        )
      end

      def poppays_sentry_projects
        headers = { "Authorization" => "Bearer #{SentrySlackBot::Config.sentry_api_token}" }
        response = HTTParty.get("https://app.getsentry.com//api/0/organizations/#{SentrySlackBot::Config.sentry_organization_slug}/projects/", headers: headers)
        JSON.parse(response.body)
      end

      def slack_channels_messages
        messages = []
        has_more = true
        oldest = Time.parse(SentrySlackBot::Config.unattended_issue_message_cut_off_date).to_i

        while has_more do
          response = HTTParty.get("https://slack.com/api/channels.history?token=#{SentrySlackBot::Config.slack_api_token}&channel=#{SentrySlackBot::Config.slack_channel_id}&oldest=#{oldest}")
          json_body = JSON.parse(response.body)
          messages << json_body['messages'].reverse
          oldest = json_body['messages'].first['ts']
          has_more = json_body['has_more']
        end

        messages.flatten
      end

      def send_message_to_thread(ts, text)
        response = HTTParty.post("https://slack.com/api/chat.postMessage?token=#{SentrySlackBot::Config.slack_api_token}&channel=#{SentrySlackBot::Config.slack_channel_id}&text=#{URI.encode(text)}&reply_broadcast=false&thread_ts=#{ts}&as_user=false&link_names=1")
        JSON.parse(response.body)
      end
    end
  end
end
