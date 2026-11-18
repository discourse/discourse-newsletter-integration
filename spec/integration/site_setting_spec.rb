# frozen_string_literal: true

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

  describe "listmonk settings" do
    it "allows empty settings before listmonk is configured" do
      %i[url api_username api_token].each do |suffix|
        expect {
          SiteSetting.public_send("discourse_newsletter_integration_listmonk_#{suffix}=", "")
        }.not_to raise_error
      end
    end

    it "accepts HTTP(S) URLs with ports, subpaths, and trailing slashes" do
      %w[
        https://news.example.com
        http://news.example.com:9000/
        https://news.example.com/newsletter/
      ].each do |url|
        expect {
          SiteSetting.discourse_newsletter_integration_listmonk_url = url
        }.not_to raise_error
      end
    end

    it "rejects malformed URLs and URLs with credentials, queries, or fragments" do
      [
        "news.example.com",
        "ftp://news.example.com",
        "https://",
        "https://user:pass@news.example.com",
        "https://news.example.com?key=value",
        "https://news.example.com/#fragment",
        "https://news.example.com:99999",
        " https://news.example.com",
      ].each do |url|
        expect { SiteSetting.discourse_newsletter_integration_listmonk_url = url }.to raise_error(
          Discourse::InvalidParameters,
        )
      end
    end

    it "accepts the username characters supported by listmonk" do
      expect {
        SiteSetting.discourse_newsletter_integration_listmonk_api_username =
          "Discourse_api-1@example.com"
      }.not_to raise_error
    end

    it "rejects invalid usernames" do
      ["ab", "user name", "user:pass", "user/name", "user\nname"].each do |username|
        expect {
          SiteSetting.discourse_newsletter_integration_listmonk_api_username = username
        }.to raise_error(Discourse::InvalidParameters)
      end
    end

    it "accepts generated listmonk API tokens" do
      expect {
        SiteSetting.discourse_newsletter_integration_listmonk_api_token = "aB09" * 12
      }.not_to raise_error
    end

    it "rejects malformed API tokens" do
      ["a" * 47, "a" * 49, "-" * 48, "a" * 47 + " ", "a" * 47 + "\n"].each do |token|
        expect {
          SiteSetting.discourse_newsletter_integration_listmonk_api_token = token
        }.to raise_error(Discourse::InvalidParameters)
      end
    end
  end
end
