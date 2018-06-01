require 'spec_helper'

describe SentrySlackBot::UnattendedIssues do
  let(:slack_channel) { SentrySlackBot::Config.slack_channel_id }
  let(:slack_token) { SentrySlackBot::Config.slack_api_token }
  let(:sentry_organization_slug) { SentrySlackBot::Config.sentry_organization_slug }
  let(:sentry_token) { SentrySlackBot::Config.sentry_api_token }
  let(:cut_off) { Time.parse(SentrySlackBot::Config.unattended_issue_message_cut_off_date).to_i }
  let(:sentry_project_1) { 'ember-app' }
  let(:sentry_project_2) { 'rails-app' }
  let(:channel_history_pagination_ts) { '1527611779.000017' }
  let(:issue_needing_notification) { '562880090' }
  let(:ts_of_issue_needing_notification) { "1527263260.000634" }
  let(:group_to_notify) { SentrySlackBot::Config.slack_group_per_sentry_project[sentry_project_1] }
  let(:expected_text) do
    URI.encode "Hey there #{group_to_notify}! This bug is unresolved and has not been assigned in Sentry. *Please assign/resolve/or 'Ignore until happens X times...'*\n If left unassigned/unresolved/unignored you will continue to receive notifications during business hours."
  end
  let(:channel_history_response_1) do
    {
      "messages"=> [
        {
          "attachments"=> [
            {
              "title_link"=>"https://sentry.io/#{sentry_organization_slug}/creators-app/issues/567051011/?referrer=slack",
            }
          ],
          "ts"=>channel_history_pagination_ts,
        },
        {
          "type"=>"message",
          "user"=>"U0MLDE1JS",
          "text"=>"it is blocking a p.r. wondering if I should just comment out the test for now",
          "ts"=>"1527262507.000197"
        }
      ],
      "has_more"=>true
    }
  end
  let(:channel_history_response_2) do
    {
      "messages"=> [
        {
          "attachments" => [
            {
              "title_link" => "https://sentry.io/#{sentry_organization_slug}/creators-web-app/issues/#{issue_needing_notification}/?referrer=slack",
            }
          ],
          "ts" => ts_of_issue_needing_notification
        }
      ],
      "has_more"=>false
    }
  end
  let(:sentry_projects_response) do
    [
      {
        "slug"=>sentry_project_1
      },
      {
        "slug"=>sentry_project_2
      }
    ]
  end
  let(:issues_response) do
    [
      {
        "id" => issue_needing_notification,
        "project" => {
          "slug" => "#{sentry_project_1}",
        }
      }
    ]
  end
  let(:issues_response_2) do
    [
      {
        "id" => '362880090'
      }
    ]
  end

  before do
    stub_request(:get, "https://slack.com/api/channels.history?channel=#{slack_channel}&oldest=#{cut_off}&token=#{slack_token}").
      to_return(body: channel_history_response_1.to_json)

    stub_request(:get, "https://slack.com/api/channels.history?channel=#{slack_channel}&oldest=#{channel_history_pagination_ts}&token=#{slack_token}").
      to_return(status: 200, body: channel_history_response_2.to_json)

    stub_request(:get, "https://app.getsentry.com//api/0/organizations/#{sentry_organization_slug}/projects/").
      with(headers: {'Authorization'=>"Bearer #{sentry_token}"}).
      to_return(status: 200, body: sentry_projects_response.to_json)

    stub_request(:get, "https://app.getsentry.com/api/0/projects/#{sentry_organization_slug}/#{sentry_project_1}/issues/?query=is:unresolved%20is:unassigned&statsPeriod=14d").
      with(headers: {'Authorization'=>"Bearer #{sentry_token}"}).
      to_return(status: 200, body: issues_response.to_json)

    stub_request(:get, "https://app.getsentry.com/api/0/projects/#{sentry_organization_slug}/#{sentry_project_2}/issues/?query=is:unresolved%20is:unassigned&statsPeriod=14d").
      with(headers: {'Authorization'=>"Bearer #{sentry_token}"}).
      to_return(status: 200, body: issues_response_2.to_json)

    stub_request(:post, /slack.com\/api\/chat.postMessage/)
      .to_return(status: 200, body: {}.to_json)

    described_class.notify!
  end

  it 'notifies issue thread in slack' do
    expect(WebMock).to have_requested(:post, "https://slack.com/api/chat.postMessage?as_user=false&channel=C0J93RMKB&link_names=1&reply_broadcast=false&text=#{expected_text}&thread_ts=#{ts_of_issue_needing_notification}&token=#{slack_token}")
  end
end
