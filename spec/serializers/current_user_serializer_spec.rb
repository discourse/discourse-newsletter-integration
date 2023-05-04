# frozen_string_literal: true

require "rails_helper"

describe CurrentUserSerializer do
  describe "#show_newsletter_subscription_banner" do
    fab!(:user) { Fabricate(:user) }
    fab!(:subscription) { Fabricate(:newsletter_user_subscription, user: user) }

    let(:json) { CurrentUserSerializer.new(user, scope: Guardian.new(user), root: nil).as_json }

    before { configure_required_settings }

    it "isn't included when the plugin isn't fully configured" do
      SiteSetting.discourse_newsletter_integration_mailchimp_api_key = ""

      expect(json.key?(:show_newsletter_subscription_banner)).to eq(false)
    end

    it "is true if the user has no subscription record" do
      subscription.update!(user_id: Fabricate(:user).id)

      expect(json[:show_newsletter_subscription_banner]).to eq(true)
    end

    it "is false if the user has an inactive subscription record" do
      subscription.update!(active: false)

      expect(json[:show_newsletter_subscription_banner]).to eq(false)
    end

    it "is false if the user has an active subscription record" do
      subscription.update!(active: true)

      expect(json[:show_newsletter_subscription_banner]).to eq(false)
    end
  end
end
