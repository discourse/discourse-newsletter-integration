# frozen_string_literal: true

require "rails_helper"

describe NewsletterIntegration::Webhooks::MailchimpController do
  fab!(:subscription) { Fabricate(:newsletter_user_subscription) }
  let(:webhook_secret) { "cca5ee606fb2be5b536547665722969f" }

  def subscribe_event_fixture(overrides = {})
    content = newsletter_integration_fixture("mailchimp/subscribe_event")
    apply_overrides_to_www_form_data(content, overrides)
  end

  def unsubscribe_event_fixture(overrides = {})
    content = newsletter_integration_fixture("mailchimp/unsubscribe_event")
    apply_overrides_to_www_form_data(content, overrides)
  end

  def apply_overrides_to_www_form_data(content, overrides)
    return content if overrides.blank?

    hash = URI.decode_www_form(content).to_h
    hash.deep_merge!(overrides)
    URI.encode_www_form(hash.to_a)
  end

  before do
    SiteSetting.discourse_newsletter_integration_enabled = true
    SiteSetting.discourse_newsletter_integration_mailchimp_webhook_secret = webhook_secret
  end

  describe "#verify" do
    it "responds with 404 if the plugin is disabled" do
      SiteSetting.discourse_newsletter_integration_enabled = false

      get "/newsletter-integration/webhooks/mailchimp/#{webhook_secret}"
      expect(response.status).to eq(404)
    end

    it "responds with 404 if the webhook secret is incorrect" do
      SiteSetting.discourse_newsletter_integration_mailchimp_webhook_secret =
        "fca5ee606fb2be5b536547665722969c"

      get "/newsletter-integration/webhooks/mailchimp/#{webhook_secret}"
      expect(response.status).to eq(404)
    end

    it "responds with 200 when the webhook secret is correct and the plugin is enabled" do
      get "/newsletter-integration/webhooks/mailchimp/#{webhook_secret}"
      expect(response.status).to eq(200)
    end
  end

  describe "#sync" do
    context "when the plugin is disabled" do
      before { SiteSetting.discourse_newsletter_integration_enabled = false }

      it "responds with 404" do
        post "/newsletter-integration/webhooks/mailchimp/#{webhook_secret}"
        expect(response.status).to eq(404)
      end
    end

    context "when the webhook secret is incorrect" do
      before do
        SiteSetting.discourse_newsletter_integration_mailchimp_webhook_secret =
          "fca5ee606fb2be5b536547665722969c"
      end

      it "responds with 404" do
        post "/newsletter-integration/webhooks/mailchimp/#{webhook_secret}"
        expect(response.status).to eq(404)
      end
    end

    context "when the plugin is enabled and the webhook secret is correct" do
      context "when the webhook is of type `subscribe`" do
        it "responds with 200 and syncs the subscription status to match the status on Mailchimp" do
          subscription.update!(active: false)

          expect_no_sync_job_enqueued(subscription.user) do
            post "/newsletter-integration/webhooks/mailchimp/#{webhook_secret}",
                 headers: {
                   "Content-Type" => "application/x-www-form-urlencoded",
                 },
                 params:
                   subscribe_event_fixture(
                     {
                       "data[email]" => subscription.user.email,
                       "data[merges][EMAIL]" => subscription.user.email,
                     },
                   )
          end

          expect(response.status).to eq(200)
          expect(subscription.reload.active).to eq(true)
        end

        it "doesn't flip the subscription status to inactive if it's already active" do
          subscription.update!(active: true)

          expect_no_sync_job_enqueued(subscription.user) do
            post "/newsletter-integration/webhooks/mailchimp/#{webhook_secret}",
                 headers: {
                   "Content-Type" => "application/x-www-form-urlencoded",
                 },
                 params:
                   subscribe_event_fixture(
                     {
                       "data[email]" => subscription.user.email,
                       "data[merges][EMAIL]" => subscription.user.email,
                     },
                   )
          end

          expect(response.status).to eq(200)
          expect(subscription.reload.active).to eq(true)
        end

        it "creates a subscription record if there's not one already" do
          user = subscription.user
          subscription.destroy!

          expect {
            expect_no_sync_job_enqueued(user) do
              post "/newsletter-integration/webhooks/mailchimp/#{webhook_secret}",
                   headers: {
                     "Content-Type" => "application/x-www-form-urlencoded",
                   },
                   params:
                     subscribe_event_fixture(
                       { "data[email]" => user.email, "data[merges][EMAIL]" => user.email },
                     )
            end
          }.to change {
            NewsletterIntegration::NewsletterUserSubscription.where(
              user_id: user.id,
              active: true,
            ).count
          }.from(0).to(1)
          expect(response.status).to eq(200)
        end

        it "doesn't error if the user can no longer be found" do
          email = subscription.user.email
          subscription.user.destroy!
          subscription.destroy!

          expect {
            expect_no_sync_job_enqueued(subscription.user) do
              post "/newsletter-integration/webhooks/mailchimp/#{webhook_secret}",
                   headers: {
                     "Content-Type" => "application/x-www-form-urlencoded",
                   },
                   params:
                     subscribe_event_fixture(
                       { "data[email]" => email, "data[merges][EMAIL]" => email },
                     )
            end
          }.not_to change { NewsletterIntegration::NewsletterUserSubscription.all.count }
          expect(response.status).to eq(200)
        end
      end

      context "when the webhook is of type `unsubscribe`" do
        it "responds with 200 and syncs the subscription status to match the status on Mailchimp" do
          subscription.update!(active: true)

          expect_no_sync_job_enqueued(subscription.user) do
            post "/newsletter-integration/webhooks/mailchimp/#{webhook_secret}",
                 headers: {
                   "Content-Type" => "application/x-www-form-urlencoded",
                 },
                 params:
                   unsubscribe_event_fixture(
                     {
                       "data[email]" => subscription.user.email,
                       "data[merges][EMAIL]" => subscription.user.email,
                     },
                   )
          end

          expect(response.status).to eq(200)
          expect(subscription.reload.active).to eq(false)
        end

        it "doesn't flip the subscription status to active if it's already inactive" do
          subscription.update!(active: false)

          expect_no_sync_job_enqueued(subscription.user) do
            post "/newsletter-integration/webhooks/mailchimp/#{webhook_secret}",
                 headers: {
                   "Content-Type" => "application/x-www-form-urlencoded",
                 },
                 params:
                   unsubscribe_event_fixture(
                     {
                       "data[email]" => subscription.user.email,
                       "data[merges][EMAIL]" => subscription.user.email,
                     },
                   )
          end

          expect(response.status).to eq(200)
          expect(subscription.reload.active).to eq(false)
        end

        it "creates a subscription record if there's not one already" do
          user = subscription.user
          subscription.destroy!

          expect {
            expect_no_sync_job_enqueued(user) do
              post "/newsletter-integration/webhooks/mailchimp/#{webhook_secret}",
                   headers: {
                     "Content-Type" => "application/x-www-form-urlencoded",
                   },
                   params:
                     unsubscribe_event_fixture(
                       { "data[email]" => user.email, "data[merges][EMAIL]" => user.email },
                     )
            end
          }.to change {
            NewsletterIntegration::NewsletterUserSubscription.where(
              user_id: user.id,
              active: false,
            ).count
          }.from(0).to(1)
          expect(response.status).to eq(200)
        end

        it "doesn't error if the user can no longer be found" do
          email = subscription.user.email
          subscription.user.destroy!
          subscription.destroy!

          expect {
            expect_no_sync_job_enqueued(subscription.user) do
              post "/newsletter-integration/webhooks/mailchimp/#{webhook_secret}",
                   headers: {
                     "Content-Type" => "application/x-www-form-urlencoded",
                   },
                   params:
                     subscribe_event_fixture(
                       { "data[email]" => email, "data[merges][EMAIL]" => email },
                     )
            end
          }.not_to change { NewsletterIntegration::NewsletterUserSubscription.all.count }
          expect(response.status).to eq(200)
        end
      end

      context "when the webhook is of an unknown type" do
        it "responds with 422" do
          post "/newsletter-integration/webhooks/mailchimp/#{webhook_secret}",
               headers: {
                 "Content-Type" => "application/x-www-form-urlencoded",
               },
               params: subscribe_event_fixture({ "type" => "badtype" })
          expect(response.status).to eq(422)
        end
      end
    end
  end
end
