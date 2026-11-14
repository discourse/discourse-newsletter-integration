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
      stub_listmonk_subscriber_lookup(subscription.user, results: [])

      create_stub =
        stub_request(:post, "https://listmonk.example.com/api/subscribers").with(
          headers: listmonk_headers,
          body: {
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
        ).to_return(status: 200, body: { data: { id: 123 } }.to_json)

      syncer.sync
      expect(create_stub).to have_been_requested
    end

    it "adds an existing subscriber to the list" do
      subscription.update!(active: true)
      stub_listmonk_subscriber_lookup(subscription.user, results: [{ id: 123 }])

      update_stub =
        stub_request(:put, "https://listmonk.example.com/api/subscribers/lists").with(
          headers: listmonk_headers,
          body: { ids: [123], action: "add", target_list_ids: [42], status: "confirmed" }.to_json,
        ).to_return(status: 200, body: { data: true }.to_json)

      syncer.sync
      expect(update_stub).to have_been_requested
    end

    it "unsubscribes an existing subscriber from the list" do
      subscription.update!(active: false)
      stub_listmonk_subscriber_lookup(subscription.user, results: [{ id: 123 }])

      update_stub =
        stub_request(:put, "https://listmonk.example.com/api/subscribers/lists").with(
          headers: listmonk_headers,
          body: { ids: [123], action: "unsubscribe", target_list_ids: [42] }.to_json,
        ).to_return(status: 200, body: { data: true }.to_json)

      syncer.sync
      expect(update_stub).to have_been_requested
    end

    it "does nothing when unsubscribing a subscriber that does not exist" do
      subscription.update!(active: false)
      stub_listmonk_subscriber_lookup(subscription.user, results: [])

      syncer.sync

      expect(WebMock).not_to have_requested(
        :put,
        "https://listmonk.example.com/api/subscribers/lists",
      )
    end

    it "uses unconfirmed status when preconfirmation is disabled" do
      SiteSetting.discourse_newsletter_integration_listmonk_preconfirm_subscriptions = false
      subscription.update!(active: true)
      stub_listmonk_subscriber_lookup(subscription.user, results: [{ id: 123 }])

      update_stub =
        stub_request(:put, "https://listmonk.example.com/api/subscribers/lists").with(
          body: hash_including(status: "unconfirmed"),
        ).to_return(status: 200, body: { data: true }.to_json)
      optin_stub =
        stub_request(:post, "https://listmonk.example.com/api/subscribers/123/optin").with(
          headers: listmonk_headers,
          body: {}.to_json,
        ).to_return(status: 200, body: { data: true }.to_json)

      syncer.sync
      expect(update_stub).to have_been_requested
      expect(optin_stub).to have_been_requested
    end

    it "raises a useful error when listmonk rejects the credentials" do
      subscription.update!(active: true)
      query =
        URI.encode_www_form(
          query: "subscribers.email = '#{subscription.user.email.downcase}'",
          per_page: 1,
        )
      stub_request(:get, "https://listmonk.example.com/api/subscribers?#{query}").to_return(
        status: 401,
        body: { message: "unauthorized" }.to_json,
      )

      expect { syncer.sync }.to raise_error(
        NewsletterIntegration::Clients::Listmonk::Error,
        /HTTP 401/,
      )
    end

    it "raises a useful error on a listmonk server error" do
      subscription.update!(active: true)
      query =
        URI.encode_www_form(
          query: "subscribers.email = '#{subscription.user.email.downcase}'",
          per_page: 1,
        )
      stub_request(:get, "https://listmonk.example.com/api/subscribers?#{query}").to_return(
        status: 500,
        body: "server error",
      )

      expect { syncer.sync }.to raise_error(
        NewsletterIntegration::Clients::Listmonk::Error,
        /HTTP 500/,
      )
    end

    it "wraps network timeouts in a listmonk error" do
      subscription.update!(active: true)
      query =
        URI.encode_www_form(
          query: "subscribers.email = '#{subscription.user.email.downcase}'",
          per_page: 1,
        )
      stub_request(:get, "https://listmonk.example.com/api/subscribers?#{query}").to_timeout

      expect { syncer.sync }.to raise_error(
        NewsletterIntegration::Clients::Listmonk::Error,
        /timed out/,
      )
    end
  end

  def configure_listmonk_settings
    SiteSetting.discourse_newsletter_integration_enabled = true
    SiteSetting.discourse_newsletter_integration_provider = "listmonk"
    SiteSetting.discourse_newsletter_integration_listmonk_url = "https://listmonk.example.com/"
    SiteSetting.discourse_newsletter_integration_listmonk_api_username = "discourse"
    SiteSetting.discourse_newsletter_integration_listmonk_api_token = "secret-token"
    SiteSetting.discourse_newsletter_integration_listmonk_list_id = 42
    SiteSetting.discourse_newsletter_integration_listmonk_preconfirm_subscriptions = true
  end

  def stub_listmonk_subscriber_lookup(user, results:)
    query = URI.encode_www_form(query: "subscribers.email = '#{user.email.downcase}'", per_page: 1)
    stub_request(:get, "https://listmonk.example.com/api/subscribers?#{query}").with(
      headers: listmonk_headers,
    ).to_return(status: 200, body: { data: { results: results } }.to_json)
  end

  def listmonk_headers
    {
      "Authorization" => "Basic #{Base64.strict_encode64("discourse:secret-token")}",
      "Content-Type" => "application/json",
    }
  end
end
