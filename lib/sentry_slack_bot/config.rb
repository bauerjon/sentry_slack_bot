module SentrySlackBot
  class Config
    class << self
      CONFIG_DEFAULTS = {
        sentry_api_token: nil,
        slack_api_token: nil,
        slack_channel_id: nil,
        sentry_organization_slug: nil,
        slack_group_per_sentry_project: Hash.new("@channel"),
        unattended_issue_message_cut_off_date: '2018-5-25',
        stale_assignment_grace_period: 7.days
      }

      CONFIG_DEFAULTS.each_key do |config_name|
        define_method :"#{config_name}" do
          self.config.send("#{config_name}") || (raise "you must define #{config_name} in config")
        end
      end

      def config
        @config ||= OpenStruct.new(CONFIG_DEFAULTS)
      end

      def configure
        yield config
      end
    end
  end
end
