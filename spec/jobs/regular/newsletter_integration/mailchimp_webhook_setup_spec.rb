# frozen_string_literal: true

require "rails_helper"

describe Jobs::NewsletterIntegration::MailchimpWebhookSetup do
  describe "#execute" do
    let(:old_secret) { SecureRandom.hex }

    before { configure_required_settings }

    it "doesn't do anything if the plugin is not fully configured" do
      SiteSetting.discourse_newsletter_integration_mailchimp_server_prefix = ""

      expect { described_class.new.execute }.not_to change {
        SiteSetting.discourse_newsletter_integration_mailchimp_webhook_secret
      }.from("")
    end

    context "when there's an existing webhook that matches the current secret" do
      it "deletes the existing webhook and creates a new one with a new secret" do
        SiteSetting.discourse_newsletter_integration_mailchimp_webhook_secret = old_secret

        get_webhooks_list_stub =
          setup_mailchimp_stub(
            :get,
            "3.0/lists/#{SiteSetting.discourse_newsletter_integration_mailchimp_list_id}/webhooks",
            response_fixture_name: "200_get_list_webhooks",
            fixture_overrides: {
              "webhooks" => [
                {
                  "id" => "existingwebhookid",
                  "url" =>
                    "http://test.localhost/newsletter-integration/webhooks/mailchimp/#{old_secret}",
                },
                { "id" => "anotherwebhook", "url" => "http://somewebsite.com/webhooks" },
              ],
            },
          )

        delete_webhook_stub =
          setup_mailchimp_stub(
            :delete,
            "3.0/lists/#{SiteSetting.discourse_newsletter_integration_mailchimp_list_id}/webhooks/existingwebhookid",
          )

        create_webhook_stub =
          setup_mailchimp_stub(
            :post,
            "3.0/lists/#{SiteSetting.discourse_newsletter_integration_mailchimp_list_id}/webhooks",
          )

        described_class.new.execute

        expect(get_webhooks_list_stub).to have_been_requested
        expect(delete_webhook_stub).to have_been_requested
        expect(create_webhook_stub).to have_been_requested

        expect(SiteSetting.discourse_newsletter_integration_mailchimp_webhook_secret).not_to eq(
          old_secret,
        )
        expect(SiteSetting.discourse_newsletter_integration_mailchimp_webhook_secret).to match(
          /\A\h{32}\z/,
        )
      end
    end

    context "when there's no existing webhook that matches the existing secret" do
      it "doesn't attempt to delete but creates a new one with a new secret" do
        SiteSetting.discourse_newsletter_integration_mailchimp_webhook_secret = old_secret

        get_webhooks_list_stub =
          setup_mailchimp_stub(
            :get,
            "3.0/lists/#{SiteSetting.discourse_newsletter_integration_mailchimp_list_id}/webhooks",
            response_fixture_name: "200_get_list_webhooks",
            fixture_overrides: {
              "webhooks" => [
                { "id" => "somewebhookk", "url" => "http://somewebsite.com/webhooks" },
              ],
            },
          )

        create_webhook_stub =
          setup_mailchimp_stub(
            :post,
            "3.0/lists/#{SiteSetting.discourse_newsletter_integration_mailchimp_list_id}/webhooks",
          )

        described_class.new.execute

        expect(get_webhooks_list_stub).to have_been_requested
        expect(create_webhook_stub).to have_been_requested

        expect(SiteSetting.discourse_newsletter_integration_mailchimp_webhook_secret).not_to eq(
          old_secret,
        )
        expect(SiteSetting.discourse_newsletter_integration_mailchimp_webhook_secret).to match(
          /\A\h{32}\z/,
        )
      end
    end

    context "when there's no existing secret" do
      it "simply creates a new webook with a new secret" do
        new_secret = nil
        create_webhook_stub =
          setup_mailchimp_stub(
            :post,
            "3.0/lists/#{SiteSetting.discourse_newsletter_integration_mailchimp_list_id}/webhooks",
            with_block: ->(req) do
              match_data =
                JSON.parse(req.body)["url"].match(
                  %r(\Ahttp://test.localhost/newsletter-integration/webhooks/mailchimp/(\h{32})\z),
                )
              next false if !match_data
              new_secret = match_data[1]
              true
            end,
          )

        described_class.new.execute

        expect(create_webhook_stub).to have_been_requested
        expect(SiteSetting.discourse_newsletter_integration_mailchimp_webhook_secret).to eq(
          new_secret,
        )
        expect(new_secret).to match(/\A\h{32}\z/)
      end
    end

    context "with subfolder setup" do
      before { set_subfolder("/forum") }

      it "creates the webhook on Mailchimp with the correct callback URL" do
        create_webhook_stub =
          setup_mailchimp_stub(
            :post,
            "3.0/lists/#{SiteSetting.discourse_newsletter_integration_mailchimp_list_id}/webhooks",
            with_block: ->(req) do
              JSON.parse(req.body)["url"].match?(
                %r(\Ahttp://test.localhost/forum/newsletter-integration/webhooks/mailchimp/(\h{32})\z),
              )
            end,
          )

        described_class.new.execute

        expect(create_webhook_stub).to have_been_requested
      end
    end

    context "when webhook creation fails" do
      it "raises an error so that sidekiq retries it later and unsets the secret" do
        SiteSetting.discourse_newsletter_integration_mailchimp_webhook_secret = old_secret

        get_webhooks_list_stub =
          setup_mailchimp_stub(
            :get,
            "3.0/lists/#{SiteSetting.discourse_newsletter_integration_mailchimp_list_id}/webhooks",
            response_fixture_name: "200_get_list_webhooks",
            fixture_overrides: {
              "webhooks" => [
                { "id" => "somewebhookk", "url" => "http://somewebsite.com/webhooks" },
              ],
            },
          )

        create_webhook_stub =
          setup_mailchimp_stub(
            :post,
            "3.0/lists/#{SiteSetting.discourse_newsletter_integration_mailchimp_list_id}/webhooks",
            status: 400,
          )

        expect { described_class.new.execute }.to raise_error(
          Jobs::NewsletterIntegration::MailchimpWebhookSetup::WebhookCreationFailed,
        )

        expect(get_webhooks_list_stub).to have_been_requested
        expect(create_webhook_stub).to have_been_requested

        expect(SiteSetting.discourse_newsletter_integration_mailchimp_webhook_secret).to eq("")
      end
    end
  end
end
