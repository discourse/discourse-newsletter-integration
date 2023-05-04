# frozen_string_literal: true

module Jobs
  module NewsletterIntegration
    class MailchimpWebhookSetup < ::Jobs::Base
      class WebhookCreationFailed < StandardError
      end

      def execute(args = {})
        return if !::NewsletterIntegration.plugin_configured?

        current_secret =
          SiteSetting.discourse_newsletter_integration_mailchimp_webhook_secret.presence
        if current_secret
          webhook = fetch_webhook_matching_secret(current_secret)
          delete_webhook(webhook["id"]) if webhook
        end

        new_secret = SecureRandom.hex
        SiteSetting.discourse_newsletter_integration_mailchimp_webhook_secret = new_secret

        begin
          create_webhook_using_secret(new_secret)
        rescue Exception
          SiteSetting.discourse_newsletter_integration_mailchimp_webhook_secret = ""
          raise
        end
      end

      private

      def fetch_webhook_matching_secret(secret)
        response = client.request(verb: "GET", path: "3.0/lists/#{list_id}/webhooks")

        json = JSON.parse(response.body)
        json["webhooks"].find { |webhook| webhook["url"] == webhook_callback_url(secret) }
      end

      def delete_webhook(webhook_id)
        client.request(verb: "DELETE", path: "3.0/lists/#{list_id}/webhooks/#{webhook_id}")
      end

      def create_webhook_using_secret(secret)
        response =
          client.request(
            verb: "POST",
            path: "3.0/lists/#{list_id}/webhooks",
            body: {
              url: webhook_callback_url(secret),
              events: {
                subscribe: true,
                unsubscribe: true,
                profile: false,
                cleaned: false,
                upemail: false,
                campaign: false,
              },
              sources: {
                user: true,
                admin: true,
                api: true,
              },
            }.to_json,
          )
        if response.code.to_i != 200
          raise WebhookCreationFailed.new(
                  "Couldn't create Mailchimp webhook via the API. Response code #{response.code.inspect}.\nBody: #{response.body.inspect}",
                )
        end
        response
      end

      def webhook_callback_url(secret)
        "#{Discourse.base_url}/newsletter-integration/webhooks/mailchimp/#{secret}"
      end

      def list_id
        SiteSetting.discourse_newsletter_integration_mailchimp_list_id
      end

      def client
        @client ||=
          begin
            ::NewsletterIntegration::Clients::Mailchimp.new(
              server_prefix: SiteSetting.discourse_newsletter_integration_mailchimp_server_prefix,
              api_key: SiteSetting.discourse_newsletter_integration_mailchimp_api_key,
            )
          end
      end
    end
  end
end
