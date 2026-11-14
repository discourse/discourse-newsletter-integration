# frozen_string_literal: true

module Jobs
  module NewsletterIntegration
    class SubscriptionSync < ::Jobs::Base
      def execute(args)
        return if !::NewsletterIntegration.plugin_configured?

        user = User.find_by(id: args[:user_id])
        return if !user

        newsletter_integration_id = args[:newsletter_integration_id]
        syncer_class =
          case SiteSetting.discourse_newsletter_integration_provider
          when "mailchimp"
            ::NewsletterIntegration::Syncers::Mailchimp
          when "listmonk"
            ::NewsletterIntegration::Syncers::Listmonk
          else
            return
          end

        syncer_class.new(user: user, newsletter_integration_id: newsletter_integration_id).sync
      end
    end
  end
end
