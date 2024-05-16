# frozen_string_literal: true

require "rails_helper"

describe SiteSerializer do
  fab!(:user)

  let(:user_json) do
    guardian = Guardian.new(user)
    SiteSerializer.new(Site.new(guardian), scope: guardian, root: nil).as_json
  end

  let(:anon_json) do
    guardian = Guardian.new(nil)
    SiteSerializer.new(Site.new(guardian), scope: guardian, root: nil).as_json
  end

  describe "#newsletter_integration_plugin_configured" do
    before { SiteSetting.discourse_newsletter_integration_enabled = true }

    it "isn't included for anonymous users" do
      configure_required_settings

      expect(anon_json.key?(:newsletter_integration_plugin_configured)).to eq(false)
    end

    it "is false if the discourse_newsletter_integration_mailchimp_server_prefix setting is not set" do
      SiteSetting.discourse_newsletter_integration_mailchimp_list_id = "somethinglistid"
      SiteSetting.discourse_newsletter_integration_mailchimp_api_key = "somethingapikey"
      SiteSetting.discourse_newsletter_integration_mailchimp_server_prefix = ""

      expect(user_json[:newsletter_integration_plugin_configured]).to eq(false)
    end

    it "is false if the discourse_newsletter_integration_mailchimp_api_key is not set" do
      SiteSetting.discourse_newsletter_integration_mailchimp_list_id = "somethinglistid"
      SiteSetting.discourse_newsletter_integration_mailchimp_api_key = ""
      SiteSetting.discourse_newsletter_integration_mailchimp_server_prefix = "us43"

      expect(user_json[:newsletter_integration_plugin_configured]).to eq(false)
    end

    it "is false if the discourse_newsletter_integration_mailchimp_list_id is not set" do
      SiteSetting.discourse_newsletter_integration_mailchimp_list_id = ""
      SiteSetting.discourse_newsletter_integration_mailchimp_api_key = "somethingapikey"
      SiteSetting.discourse_newsletter_integration_mailchimp_server_prefix = "us43"

      expect(user_json[:newsletter_integration_plugin_configured]).to eq(false)
    end

    it "is true if all the required settings are set" do
      SiteSetting.discourse_newsletter_integration_mailchimp_list_id = "somethinglistid"
      SiteSetting.discourse_newsletter_integration_mailchimp_api_key = "somethingapikey"
      SiteSetting.discourse_newsletter_integration_mailchimp_server_prefix = "us43"

      expect(user_json[:newsletter_integration_plugin_configured]).to eq(true)
    end
  end
end
