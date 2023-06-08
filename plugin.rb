# frozen_string_literal: true

# name: discourse-newsletter-integration
# about: A plugin to add integrations with mailing list services to Discourse
# version: 0.0.1
# authors: Discourse
# url: https://github.com/discourse/discourse-newsletter-integration
# required_version: 2.7.0

enabled_site_setting :discourse_newsletter_integration_enabled

register_asset "stylesheets/common/index.scss"

module ::NewsletterIntegration
  PLUGIN_NAME = "discourse-newsletter-integration"
  GLOBAL_NEWSLETTER_ID = -1

  def self.plugin_configured?
    SiteSetting.discourse_newsletter_integration_enabled &&
      SiteSetting.discourse_newsletter_integration_mailchimp_api_key.present? &&
      SiteSetting.discourse_newsletter_integration_mailchimp_list_id.present? &&
      SiteSetting.discourse_newsletter_integration_mailchimp_server_prefix.present?
  end
end

require_relative "lib/newsletter_integration/engine"

after_initialize do
  Discourse::Application.routes.append do
    mount ::NewsletterIntegration::Engine, at: "/newsletter-integration"
  end

  register_modifier(:users_controller_update_user_params) do |result, _, params|
    next result if !NewsletterIntegration.plugin_configured?

    val = params[:newsletter_integration_subscribe_global_newsletter].to_s.presence
    result[:newsletter_integration_subscribe_global_newsletter] = val == "true" if val
    result
  end

  on(:within_user_updater_transaction) do |user, attributes|
    next if !NewsletterIntegration.plugin_configured?

    if attributes.key?(:newsletter_integration_subscribe_global_newsletter)
      enable = attributes[:newsletter_integration_subscribe_global_newsletter]
      subscription =
        NewsletterIntegration::NewsletterUserSubscription.find_or_initialize_by(
          user_id: user.id,
          newsletter_integration_id: NewsletterIntegration::GLOBAL_NEWSLETTER_ID,
        )
      if enable
        subscription.ensure_active!
      else
        subscription.new_record? ? subscription.save! : subscription.ensure_inactive!
      end
    end
  end

  on(:site_setting_changed) do |name, old_val, current_val|
    if !%i[
         discourse_newsletter_integration_mailchimp_api_key
         discourse_newsletter_integration_mailchimp_server_prefix
         discourse_newsletter_integration_mailchimp_list_id
       ].include?(name)
      next
    end
    next if !NewsletterIntegration.plugin_configured?

    Jobs.enqueue(Jobs::NewsletterIntegration::MailchimpWebhookSetup)
  end

  add_to_serializer(
    :user,
    :newsletter_integration_subscribe_global_newsletter,
    include_condition: -> { NewsletterIntegration.plugin_configured? },
  ) do
    NewsletterIntegration::NewsletterUserSubscription.exists?(
      user_id: object.id,
      newsletter_integration_id: NewsletterIntegration::GLOBAL_NEWSLETTER_ID,
      active: true,
    )
  end

  add_to_serializer(
    :site,
    :newsletter_integration_plugin_configured,
    include_condition: -> { scope.user.present? },
  ) { NewsletterIntegration.plugin_configured? }

  add_to_serializer(
    :current_user,
    :show_newsletter_subscription_banner,
    include_condition: -> { NewsletterIntegration.plugin_configured? },
  ) do
    !NewsletterIntegration::NewsletterUserSubscription.exists?(
      user_id: object.id,
      newsletter_integration_id: NewsletterIntegration::GLOBAL_NEWSLETTER_ID,
    )
  end
end
