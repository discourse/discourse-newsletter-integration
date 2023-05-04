# frozen_string_literal: true

require "rails_helper"

describe "site setting checks" do
  describe "discourse_newsletter_integration_mailchimp_server_prefix setting" do
    it "doesn't allow non-alphanumeric characters to prevent SSRF" do
      expect {
        SiteSetting.discourse_newsletter_integration_mailchimp_server_prefix = "evilhacker.com/us14"
      }.to raise_error(Discourse::InvalidParameters)
    end

    it "allows alphanumeric characters" do
      expect {
        SiteSetting.discourse_newsletter_integration_mailchimp_server_prefix = "us14"
      }.not_to raise_error
    end
  end
end
