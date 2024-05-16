# frozen_string_literal: true

require "rails_helper"

describe UsersController do
  fab!(:user)

  before { sign_in(user) }

  describe "#update" do
    before { configure_required_settings }

    context "when the newsletter_integration_subscribe_global_newsletter is true" do
      it "creates new subscription record when there's no existing record" do
        expect {
          expect_sync_job_enqueued(user) do
            put "/u/#{user.username}.json",
                params: {
                  newsletter_integration_subscribe_global_newsletter: "true",
                }
          end
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

        expect_sync_job_enqueued(user) do
          put "/u/#{user.username}.json",
              params: {
                newsletter_integration_subscribe_global_newsletter: "true",
              }
        end

        expect(response.status).to eq(200)
        expect(subscription.reload.active).to eq(true)
      end

      it "doesn't change the active field to false of an existing subscription record" do
        subscription = Fabricate(:newsletter_user_subscription, user: user, active: true)

        expect_no_sync_job_enqueued(user) do
          put "/u/#{user.username}.json",
              params: {
                newsletter_integration_subscribe_global_newsletter: "true",
              }
        end

        expect(response.status).to eq(200)
        expect(subscription.reload.active).to eq(true)
      end

      context "with rate limits" do
        before { RateLimiter.enable }

        use_redis_snapshotting

        it "doesn't allow the user to subscribe more often than what the rate limits allow" do
          freeze_time do
            NewsletterIntegration::NewsletterUserSubscription.subscription_change_limit_per_hour = 1

            subscription = Fabricate(:newsletter_user_subscription, user: user, active: false)

            put "/u/#{user.username}.json",
                params: {
                  newsletter_integration_subscribe_global_newsletter: "true",
                }

            expect(response.status).to eq(200)
            expect(subscription.reload.active).to eq(true)

            subscription.update!(active: false)

            put "/u/#{user.username}.json",
                params: {
                  newsletter_integration_subscribe_global_newsletter: "true",
                }

            expect(subscription.reload.active).to eq(false)

            expect(response.status).to eq(429)
            expect(response.parsed_body["errors"]).to include(
              I18n.t(
                "rate_limiter.by_type.newsletter_integration_change_subscription",
                time_left: RateLimiter.time_left(1.hour.to_i),
              ),
            )
            expect(response.headers["Retry-After"].to_i).to be_within(1).of(3600)
          end
        end
      end
    end

    context "when the newsletter_integration_subscribe_global_newsletter is false" do
      it "creates new subscription record when there's no existing record" do
        expect {
          expect_no_sync_job_enqueued(user) do
            put "/u/#{user.username}.json",
                params: {
                  newsletter_integration_subscribe_global_newsletter: "false",
                }
          end
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

        expect_sync_job_enqueued(user) do
          put "/u/#{user.username}.json",
              params: {
                newsletter_integration_subscribe_global_newsletter: "false",
              }
        end

        expect(response.status).to eq(200)
        expect(subscription.reload.active).to eq(false)
      end

      it "doesn't change the active field to true of an existing subscription record" do
        subscription = Fabricate(:newsletter_user_subscription, user: user, active: false)

        expect_no_sync_job_enqueued(user) do
          put "/u/#{user.username}.json",
              params: {
                newsletter_integration_subscribe_global_newsletter: "false",
              }
        end

        expect(response.status).to eq(200)
        expect(subscription.reload.active).to eq(false)
      end

      context "with rate limits" do
        before { RateLimiter.enable }

        use_redis_snapshotting

        it "doesn't allow the user to unsubscribe more often than what the rate limits allow" do
          freeze_time do
            NewsletterIntegration::NewsletterUserSubscription.subscription_change_limit_per_hour = 1

            subscription = Fabricate(:newsletter_user_subscription, user: user, active: true)

            put "/u/#{user.username}.json",
                params: {
                  newsletter_integration_subscribe_global_newsletter: "false",
                }

            expect(response.status).to eq(200)
            expect(subscription.reload.active).to eq(false)

            subscription.update!(active: true)

            put "/u/#{user.username}.json",
                params: {
                  newsletter_integration_subscribe_global_newsletter: "false",
                }

            expect(subscription.reload.active).to eq(true)

            expect(response.status).to eq(429)
            expect(response.parsed_body["errors"]).to include(
              I18n.t(
                "rate_limiter.by_type.newsletter_integration_change_subscription",
                time_left: RateLimiter.time_left(1.hour.to_i),
              ),
            )
            expect(response.headers["Retry-After"].to_i).to be_within(1).of(3600)
          end
        end
      end
    end

    context "when the plugin isn't fully configured" do
      before { SiteSetting.discourse_newsletter_integration_mailchimp_server_prefix = "" }

      it "ignores the newsletter_integration_subscribe_global_newsletter param" do
        expect_no_sync_job_enqueued(user) do
          put "/u/#{user.username}.json",
              params: {
                newsletter_integration_subscribe_global_newsletter: "true",
              }
        end

        expect(response.status).to eq(200)
        expect(NewsletterIntegration::NewsletterUserSubscription.all.count).to eq(0)
      end
    end
  end
end
