# frozen_string_literal: true

Fabricator(
  :newsletter_user_subscription,
  class_name: "NewsletterIntegration::NewsletterUserSubscription",
) do
  newsletter_integration_id NewsletterIntegration::GLOBAL_NEWSLETTER_ID
  user
end
