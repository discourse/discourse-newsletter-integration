# frozen_string_literal: true

require "rails_helper"

describe Jobs::NewsletterIntegration::SubscriptionSync do
  fab!(:subscription) { Fabricate(:newsletter_user_subscription) }

  before { configure_required_settings }

  describe "#execute" do
    it "doesn't do anything if the plugin isn't fully configured" do
      subscription.update!(active: true)

      SiteSetting.discourse_newsletter_integration_mailchimp_server_prefix = ""

      described_class.new.execute(
        {
          user_id: subscription.user.id,
          newsletter_integration_id: subscription.newsletter_integration_id,
        },
      )
      # there are no stubs set up so if it tried to sync it would raise
      # WebMock::NetConnectNotAllowedError
    end

    it "doesn't do anything if the user can not be found" do
      subscription.update!(active: true)
      user_id = subscription.user.id
      subscription.user.destroy!

      described_class.new.execute(
        { user_id: user_id, newsletter_integration_id: subscription.newsletter_integration_id },
      )
      # there are no stubs set up so if it tried to sync it would raise
      # WebMock::NetConnectNotAllowedError
    end

    it "syncs the user's subscription when it's active" do
      subscription.update!(active: true)

      stub = setup_subscribe_request_stub(:mailchimp, subscription.user)
      described_class.new.execute(
        {
          user_id: subscription.user.id,
          newsletter_integration_id: subscription.newsletter_integration_id,
        },
      )
      expect(stub).to have_been_requested
    end

    it "syncs the user's subscription when it's inactive" do
      subscription.update!(active: false)

      stub = setup_unsubscribe_request_stub(:mailchimp, subscription.user)
      described_class.new.execute(
        {
          user_id: subscription.user.id,
          newsletter_integration_id: subscription.newsletter_integration_id,
        },
      )
      expect(stub).to have_been_requested
    end
  end
end
