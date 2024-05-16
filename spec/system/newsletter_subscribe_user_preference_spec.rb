# frozen_string_literal: true

require "rails_helper"

describe "Newsletter Subsribe User Preference", type: :system, js: true do
  fab!(:user)
  fab!(:subscription) { Fabricate(:newsletter_user_subscription, user: user) }

  before do
    configure_required_settings
    sign_in(user)
  end

  context "when the subscription is active" do
    before { subscription.update!(active: true) }

    it "the checkbox is on by default" do
      visit("/u/#{user.username}/preferences/emails")
      expect(
        find(".newsletter-integration-subscribe-section .subscribe-checkbox input").checked?,
      ).to eq(true)
    end

    it "the subscription can be changed to inactive by unchecking the checkbox and saving preferences" do
      visit("/u/#{user.username}/preferences/emails")

      find(".newsletter-integration-subscribe-section .subscribe-checkbox input").click
      find(".user-preferences .save-changes").click

      expect(find(".user-preferences")).to have_content(I18n.t("js.saved"))
      expect(subscription.reload.active).to eq(false)
    end
  end

  context "when the subscription is inactive" do
    before { subscription.update!(active: false) }

    it "the checkbox is off by default" do
      visit("/u/#{user.username}/preferences/emails")
      expect(
        find(".newsletter-integration-subscribe-section .subscribe-checkbox input").checked?,
      ).to eq(false)
    end

    it "the subscription can be changed to active by checking the checkbox and saving preferences" do
      visit("/u/#{user.username}/preferences/emails")

      find(".newsletter-integration-subscribe-section .subscribe-checkbox input").click
      find(".user-preferences .save-changes").click

      expect(find(".user-preferences")).to have_content(I18n.t("js.saved"))
      expect(subscription.reload.active).to eq(true)
    end
  end
end
