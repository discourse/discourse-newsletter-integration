# frozen_string_literal: true

module NewsletterIntegration
  module Syncers
    class Base
      attr_reader :user, :newsletter_integration_id

      def initialize(user:, newsletter_integration_id:)
        @user = user
        @newsletter_integration_id = newsletter_integration_id
      end

      def sync
        subscription =
          NewsletterUserSubscription.find_by(
            user_id: user.id,
            newsletter_integration_id: newsletter_integration_id,
          )
        if subscription&.active?
          subscribe!
        else
          unsubscribe!
        end
      end

      private

      def subscribe!
        raise "Not implemented!"
      end

      def unsubscribe!
        raise "Not implemented!"
      end
    end
  end
end
