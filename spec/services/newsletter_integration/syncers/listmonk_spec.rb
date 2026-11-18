# frozen_string_literal: true

describe NewsletterIntegration::Syncers::Listmonk do
  fab!(:subscription, :newsletter_user_subscription)

  subject(:syncer) do
    described_class.new(
      user: subscription.user,
      newsletter_integration_id: subscription.newsletter_integration_id,
    )
  end

  before { configure_listmonk_settings }

  describe "#sync" do
    it "creates and subscribes a subscriber that does not exist" do
      subscription.update!(active: true)
      stub_listmonk_subscriber_lookup(subscription.user)
      create_stub =
        setup_listmonk_stub(
          :post,
          "api/subscribers",
          request_body: {
            email: subscription.user.email,
            name: subscription.user.name || subscription.user.username,
            status: "enabled",
            lists: [42],
            attribs: {
              discourse_username: subscription.user.username,
              discourse_user_id: subscription.user.id,
            },
            preconfirm_subscriptions: true,
          }.to_json,
          response_body: {
            data: {
              id: 123,
            },
          },
        )

      syncer.sync
      expect(create_stub).to have_been_requested
    end

    it "adds an existing subscriber to the list" do
      subscription.update!(active: true)
      stub_listmonk_subscriber_lookup(subscription.user, results: [{ id: 123 }])
      update_stub =
        setup_listmonk_stub(
          :put,
          "api/subscribers/lists",
          request_body: {
            ids: [123],
            action: "add",
            target_list_ids: [42],
            status: "confirmed",
          }.to_json,
        )

      syncer.sync
      expect(update_stub).to have_been_requested
    end

    it "unsubscribes an existing subscriber from the list" do
      subscription.update!(active: false)
      stub_listmonk_subscriber_lookup(subscription.user, results: [{ id: 123 }])
      update_stub =
        setup_listmonk_stub(
          :put,
          "api/subscribers/lists",
          request_body: { ids: [123], action: "unsubscribe", target_list_ids: [42] }.to_json,
        )

      syncer.sync
      expect(update_stub).to have_been_requested
    end

    it "does nothing when unsubscribing a subscriber that does not exist" do
      subscription.update!(active: false)
      lookup_stub = stub_listmonk_subscriber_lookup(subscription.user)

      syncer.sync
      expect(lookup_stub).to have_been_requested.once
      # WebMock rejects any unstubbed membership update.
    end

    it "uses unconfirmed status when preconfirmation is disabled" do
      SiteSetting.discourse_newsletter_integration_listmonk_preconfirm_subscriptions = false
      subscription.update!(active: true)
      stub_listmonk_subscriber_lookup(subscription.user, results: [{ id: 123 }])
      update_stub =
        setup_listmonk_stub(
          :put,
          "api/subscribers/lists",
          request_body: {
            ids: [123],
            action: "add",
            target_list_ids: [42],
            status: "unconfirmed",
          }.to_json,
        )
      optin_stub = setup_listmonk_stub(:post, "api/subscribers/123/optin", request_body: {}.to_json)

      syncer.sync
      expect(update_stub).to have_been_requested
      expect(optin_stub).to have_been_requested
    end

    [401, 500].each do |status|
      it "raises a useful error when listmonk returns HTTP #{status}" do
        subscription.update!(active: true)
        stub_listmonk_subscriber_lookup(subscription.user, status: status)

        expect { syncer.sync }.to raise_error(
          NewsletterIntegration::Clients::Listmonk::Error,
          /HTTP #{status}/,
        )
      end
    end

    it "wraps network timeouts in a listmonk error" do
      subscription.update!(active: true)
      stub_listmonk_subscriber_lookup(subscription.user, timeout: true)

      expect { syncer.sync }.to raise_error(
        NewsletterIntegration::Clients::Listmonk::Error,
        /timed out/,
      )
    end
  end
end
