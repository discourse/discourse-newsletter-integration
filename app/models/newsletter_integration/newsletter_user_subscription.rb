# frozen_string_literal: true

module NewsletterIntegration
  class NewsletterUserSubscription < ::ActiveRecord::Base
    self.table_name = "newsletter_user_subscriptions"

    belongs_to :user

    def self.subscription_change_limit_per_hour
      @subscription_change_limit_per_hour || 5
    end

    def self.subscription_change_limit_per_hour=(val)
      @subscription_change_limit_per_hour = val
    end

    def ensure_active!
      toggle_active if !active?
    end

    def ensure_inactive!
      toggle_active if active?
    end

    private

    def toggle_active
      with_rate_limits do
        self.active = !self.active
        self.save!
        DB.after_commit do
          Jobs.enqueue(
            Jobs::NewsletterIntegration::SubscriptionSync,
            user_id: self.user_id,
            newsletter_integration_id: self.newsletter_integration_id,
          )
        end
      end
    end

    def with_rate_limits
      RateLimiter.new(
        self.user,
        "newsletter-integration-change-subscription",
        self.class.subscription_change_limit_per_hour,
        1.hour,
        error_code: "newsletter_integration_subscription_change_limit",
      ).performed!
      yield
    end
  end
end

# == Schema Information
#
# Table name: newsletter_user_subscriptions
#
#  id                        :bigint           not null, primary key
#  newsletter_integration_id :integer          not null
#  user_id                   :integer          not null
#  active                    :boolean          default(FALSE), not null
#  created_at                :datetime         not null
#  updated_at                :datetime         not null
#
# Indexes
#
#  newsletter_user_subscriptions_user_id_newsletter_id_uniq  (user_id,newsletter_integration_id) UNIQUE
#
