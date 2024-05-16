# frozen_string_literal: true

module NewsletterIntegration
  class Webhooks::MailchimpController < ::ApplicationController
    # rubocop:disable Discourse/Plugins/CallRequiresPlugin
    class BadSecret < StandardError
    end
    # rubocop:enable Discourse/Plugins/CallRequiresPlugin

    requires_plugin NewsletterIntegration::PLUGIN_NAME

    before_action :verify_shared_secret
    skip_before_action :check_xhr, :redirect_to_login_if_required, :verify_authenticity_token

    rescue_from BadSecret do
      render body: "not ok", status: 404
    end

    # when a webhook is created on Mailchimp, they test the callback URL with a
    # GET request and expect a 200 response to allow the webhook to be created.
    def verify
      render body: "ok", status: 200
    end

    def sync
      type = params.require(:type)
      email = params.require(:data).require(:email)

      desired_active_state = nil
      case type
      when "subscribe"
        desired_active_state = true
      when "unsubscribe"
        desired_active_state = false
      else
        Rails.logger.warn("Mailchimp webhooks controller: unknown event type #{type.inspect}.")
        render body: "not ok", status: 422
        return
      end

      user = User.find_by_email(email)
      if user
        subscription =
          NewsletterUserSubscription.find_or_initialize_by(
            user_id: user.id,
            newsletter_integration_id: GLOBAL_NEWSLETTER_ID,
          )
        subscription.active = desired_active_state
        subscription.save!
      end
      render body: "ok", status: 200
    end

    private

    def verify_shared_secret
      request_secret = params[:secret].to_s.presence
      actual_secret = SiteSetting.discourse_newsletter_integration_mailchimp_webhook_secret.presence

      if !request_secret || !actual_secret ||
           !ActiveSupport::SecurityUtils.secure_compare(request_secret, actual_secret)
        raise BadSecret.new
      end
    end
  end
end
