# frozen_string_literal: true

module NewsletterIntegration
  module Syncers
    class Listmonk < Base
      private

      def subscribe!
        subscriber = find_subscriber

        if subscriber
          update_list_membership(subscriber["id"], action: "add", status: subscription_status)
          send_optin!(subscriber["id"]) if !preconfirm_subscriptions?
        else
          client.request(
            verb: "POST",
            path: "api/subscribers",
            body: {
              email: user.email,
              name: user.name.presence || user.username,
              status: "enabled",
              lists: [list_id],
              attribs: {
                discourse_username: user.username,
                discourse_user_id: user.id,
              },
              preconfirm_subscriptions: preconfirm_subscriptions?,
            },
          )
        end
      end

      def unsubscribe!
        subscriber = find_subscriber
        return if !subscriber

        update_list_membership(subscriber["id"], action: "unsubscribe")
      end

      def find_subscriber
        response =
          client.request(
            verb: "GET",
            path: "api/subscribers",
            query: {
              query: "subscribers.email = '#{escaped_email}'",
              per_page: 1,
            },
          )

        JSON.parse(response.body).dig("data", "results")&.first
      end

      def send_optin!(subscriber_id)
        client.request(verb: "POST", path: "api/subscribers/#{subscriber_id}/optin", body: {})
      end

      def update_list_membership(subscriber_id, action:, status: nil)
        body = { ids: [subscriber_id], action: action, target_list_ids: [list_id] }
        body[:status] = status if status

        client.request(verb: "PUT", path: "api/subscribers/lists", body: body)
      end

      def client
        @client ||=
          Clients::Listmonk.new(
            base_url: SiteSetting.discourse_newsletter_integration_listmonk_url,
            api_username: SiteSetting.discourse_newsletter_integration_listmonk_api_username,
            api_token: SiteSetting.discourse_newsletter_integration_listmonk_api_token,
          )
      end

      def escaped_email
        user.email.downcase.gsub("'", "''")
      end

      def list_id
        SiteSetting.discourse_newsletter_integration_listmonk_list_id
      end

      def preconfirm_subscriptions?
        SiteSetting.discourse_newsletter_integration_listmonk_preconfirm_subscriptions
      end

      def subscription_status
        preconfirm_subscriptions? ? "confirmed" : "unconfirmed"
      end
    end
  end
end
