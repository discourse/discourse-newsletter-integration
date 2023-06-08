# frozen_string_literal: true

require "rails_helper"

describe NewsletterIntegration::NewsletterSubscriptionController do
  fab!(:user) { Fabricate(:user) }

  before { configure_required_settings }

  describe "#subscribe" do
    it "responds with 403 for anonymous users" do
      post "/newsletter-integration/subscriptions.json"

      expect(response.status).to eq(403)
      expect(NewsletterIntegration::NewsletterUserSubscription.all.count).to eq(0)
    end

    context "when there's a logged in user" do
      before { sign_in(user) }

      it "responds with 404 if the plugin isn't fully configured" do
        SiteSetting.discourse_newsletter_integration_mailchimp_api_key = ""

        post "/newsletter-integration/subscriptions.json"

        expect(response.status).to eq(404)
        expect(NewsletterIntegration::NewsletterUserSubscription.all.count).to eq(0)
      end

      it "creates new subscription record when there's no existing record" do
        expect {
          expect_sync_job_enqueued(user) { post "/newsletter-integration/subscriptions.json" }
        }.to change {
          NewsletterIntegration::NewsletterUserSubscription.where(
            user_id: user.id,
            active: true,
          ).count
        }.from(0).to(1)

        expect(response.status).to eq(200)
      end

      it "updates the active field to true of an existing subscription record" do
        subscription = Fabricate(:newsletter_user_subscription, user: user, active: false)

        expect_sync_job_enqueued(user) { post "/newsletter-integration/subscriptions.json" }

        expect(response.status).to eq(200)
        expect(subscription.reload.active).to eq(true)
      end

      it "doesn't change the active field to false of an existing subscription record" do
        subscription = Fabricate(:newsletter_user_subscription, user: user, active: true)

        expect_no_sync_job_enqueued(user) { post "/newsletter-integration/subscriptions.json" }

        expect(response.status).to eq(200)
        expect(subscription.reload.active).to eq(true)
      end

      context "with rate limits" do
        before { RateLimiter.enable }

        it "doesn't allow the user to subscribe more often than what the rate limits allow" do
          freeze_time do
            NewsletterIntegration::NewsletterUserSubscription.subscription_change_limit_per_hour = 1

            subscription = Fabricate(:newsletter_user_subscription, user: user, active: false)

            post "/newsletter-integration/subscriptions.json"

            expect(response.status).to eq(200)
            expect(subscription.reload.active).to eq(true)

            subscription.update!(active: false)

            post "/newsletter-integration/subscriptions.json"

            expect(subscription.reload.active).to eq(false)

            expect(response.status).to eq(429)
            expect(response.parsed_body["errors"]).to include(
              I18n.t(
                "rate_limiter.by_type.newsletter_integration_change_subscription",
                time_left: RateLimiter.time_left(1.hour.to_i),
              ),
            )
            expect(response.headers["Retry-After"].to_i).to be_within(1).of(3600)
          ensure
            RateLimiter.clear_all!
          end
        end
      end
    end
  end

  describe "#unsubscribe" do
    it "responds with 403 for anonymous users" do
      delete "/newsletter-integration/subscriptions.json"
      expect(response.status).to eq(403)
    end

    context "when there's a logged in user" do
      before { sign_in(user) }

      it "responds with 404 if the plugin isn't fully configured" do
        SiteSetting.discourse_newsletter_integration_mailchimp_api_key = ""

        subscription = Fabricate(:newsletter_user_subscription, user: user, active: true)

        delete "/newsletter-integration/subscriptions.json"

        expect(response.status).to eq(404)
        expect(subscription.reload.active).to eq(true)
      end

      it "creates new subscription record when there's no existing record" do
        expect {
          expect_no_sync_job_enqueued(user) { delete "/newsletter-integration/subscriptions.json" }
        }.to change {
          NewsletterIntegration::NewsletterUserSubscription.where(
            user_id: user.id,
            active: false,
          ).count
        }.from(0).to(1)

        expect(response.status).to eq(200)
      end

      it "updates the active field to false of an existing subscription record" do
        subscription = Fabricate(:newsletter_user_subscription, user: user, active: true)

        expect_sync_job_enqueued(user) { delete "/newsletter-integration/subscriptions.json" }

        expect(response.status).to eq(200)
        expect(subscription.reload.active).to eq(false)
      end

      it "doesn't change the active field to true of an existing subscription record" do
        subscription = Fabricate(:newsletter_user_subscription, user: user, active: false)

        expect_no_sync_job_enqueued(user) { delete "/newsletter-integration/subscriptions.json" }

        expect(response.status).to eq(200)
        expect(subscription.reload.active).to eq(false)
      end

      context "with rate limits" do
        before { RateLimiter.enable }

        it "doesn't allow the user to unsubscribe more often than what the rate limits allow" do
          freeze_time do
            NewsletterIntegration::NewsletterUserSubscription.subscription_change_limit_per_hour = 1

            subscription = Fabricate(:newsletter_user_subscription, user: user, active: true)

            delete "/newsletter-integration/subscriptions.json"

            expect(response.status).to eq(200)
            expect(subscription.reload.active).to eq(false)

            subscription.update!(active: true)

            delete "/newsletter-integration/subscriptions.json"

            expect(subscription.reload.active).to eq(true)

            expect(response.status).to eq(429)
            expect(response.parsed_body["errors"]).to include(
              I18n.t(
                "rate_limiter.by_type.newsletter_integration_change_subscription",
                time_left: RateLimiter.time_left(1.hour.to_i),
              ),
            )
            expect(response.headers["Retry-After"].to_i).to be_within(1).of(3600)
          ensure
            RateLimiter.clear_all!
          end
        end
      end
    end
  end
end
