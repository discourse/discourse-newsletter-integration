# frozen_string_literal: true

module NewsletterIntegration
  class NewsletterSubscriptionController < ::ApplicationController
    requires_plugin NewsletterIntegration::PLUGIN_NAME
    requires_login

    before_action :ensure_plugin_configured

    def subscribe
      subscription =
        NewsletterUserSubscription.find_or_initialize_by(
          user_id: current_user.id,
          newsletter_integration_id: GLOBAL_NEWSLETTER_ID,
        )
      subscription.ensure_active!
      render json: success_json, status: 200
    end

    def unsubscribe
      subscription =
        NewsletterUserSubscription.find_or_initialize_by(
          user_id: current_user.id,
          newsletter_integration_id: GLOBAL_NEWSLETTER_ID,
        )
      if subscription.new_record?
        # new subscriptions are initialized with `active: false` by default.
        # so just persist and move on
        subscription.save!
      else
        subscription.ensure_inactive!
      end
      render json: success_json, status: 200
    end

    private

    def ensure_plugin_configured
      raise Discourse::NotFound if !NewsletterIntegration.plugin_configured?
    end
  end
end
