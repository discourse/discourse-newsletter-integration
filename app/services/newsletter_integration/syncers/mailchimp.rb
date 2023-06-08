# frozen_string_literal: true

module NewsletterIntegration
  module Syncers
    class Mailchimp < Base
      private

      def subscribe!
        add_or_update_list_member(status: "subscribed")
      end

      def unsubscribe!
        add_or_update_list_member(status: "unsubscribed")
      end

      def add_or_update_list_member(status:)
        client =
          Clients::Mailchimp.new(
            server_prefix: SiteSetting.discourse_newsletter_integration_mailchimp_server_prefix,
            api_key: SiteSetting.discourse_newsletter_integration_mailchimp_api_key,
          )

        # Mailchimp docs for this endpoint:
        # https://mailchimp.com/developer/marketing/api/list-members/add-or-update-list-member/
        client.request(
          verb: "PUT",
          path: "3.0/lists/#{list_id}/members/#{user_email_md5}",
          body: {
            status: status,
            email_address: user.email,
            merge_fields: {
              FNAME: user.name || user.username,
            },
          }.to_json,
        )
      end

      def user_email_md5
        Digest::MD5.hexdigest(user.email.downcase)
      end

      def list_id
        SiteSetting.discourse_newsletter_integration_mailchimp_list_id
      end
    end
  end
end
