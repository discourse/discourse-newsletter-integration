# frozen_string_literal: true

require "rails_helper"

describe UserSerializer do
  describe "#newsletter_integration_subscribe_global_newsletter" do
    fab!(:user) { Fabricate(:user) }
    fab!(:subscription) { Fabricate(:newsletter_user_subscription, user: user) }

    let(:json) { UserSerializer.new(user, scope: Guardian.new(user), root: nil).as_json }

    before { configure_required_settings }

    it "isn't included when the plugin isn't fully configured" do
      SiteSetting.discourse_newsletter_integration_mailchimp_list_id = ""

      expect(json.key?(:newsletter_integration_subscribe_global_newsletter)).to eq(false)
    end

    it "is false when the subscription is inactive" do
      subscription.update!(active: false)

      expect(json[:newsletter_integration_subscribe_global_newsletter]).to eq(false)
    end

    it "is false when the user doesn't have a subscription" do
      subscription.update!(user_id: Fabricate(:user).id, active: true)

      expect(json[:newsletter_integration_subscribe_global_newsletter]).to eq(false)
    end

    it "is true when the subscription is active" do
      subscription.update!(active: true)

      expect(json[:newsletter_integration_subscribe_global_newsletter]).to eq(true)
    end
  end
end
