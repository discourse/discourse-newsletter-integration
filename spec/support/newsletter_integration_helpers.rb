# frozen_string_literal: true

module NewsletterIntegrationHelpers
  def configure_required_settings
    SiteSetting.discourse_newsletter_integration_enabled = true
    SiteSetting.discourse_newsletter_integration_mailchimp_api_key = "somemailchimpapikey"
    SiteSetting.discourse_newsletter_integration_mailchimp_list_id = "mailchimplistid"
    SiteSetting.discourse_newsletter_integration_mailchimp_server_prefix = "us14"
  end

  def expect_sync_job_enqueued(user, &blk)
    expect_enqueued_with(
      job: Jobs::NewsletterIntegration::SubscriptionSync,
      args: {
        user_id: user.id,
        newsletter_integration_id: NewsletterIntegration::GLOBAL_NEWSLETTER_ID,
      },
      &blk
    )
  end

  def expect_no_sync_job_enqueued(user, &blk)
    expect_not_enqueued_with(
      job: Jobs::NewsletterIntegration::SubscriptionSync,
      args: {
        user_id: user.id,
        newsletter_integration_id: NewsletterIntegration::GLOBAL_NEWSLETTER_ID,
      },
      &blk
    )
  end

  def setup_subscribe_request_stub(provider, user)
    case provider
    when :mailchimp
      list_id = SiteSetting.discourse_newsletter_integration_mailchimp_list_id
      email_md5 = Digest::MD5.hexdigest(user.email.downcase)
      path = "3.0/lists/#{list_id}/members/#{email_md5}"

      setup_mailchimp_stub(
        :put,
        path,
        request_body: {
          status: "subscribed",
          email_address: user.email,
          merge_fields: {
            FNAME: user.name,
          },
        }.to_json,
        response_fixture_name: "200_put_add_or_update_member_subscribe",
      )
    else
      raise "unknown provider #{provider.inspect}"
    end
  end

  def setup_unsubscribe_request_stub(provider, user)
    case provider
    when :mailchimp
      list_id = SiteSetting.discourse_newsletter_integration_mailchimp_list_id
      email_md5 = Digest::MD5.hexdigest(user.email.downcase)
      path = "3.0/lists/#{list_id}/members/#{email_md5}"

      setup_mailchimp_stub(
        :put,
        path,
        request_body: {
          status: "unsubscribed",
          email_address: user.email,
          merge_fields: {
            FNAME: user.name,
          },
        }.to_json,
        response_fixture_name: "200_put_add_or_update_member_unsubscribe",
      )
    else
      raise "unknown provider #{provider.inspect}"
    end
  end

  def setup_mailchimp_stub(
    verb,
    path,
    request_body: nil,
    status: 200,
    response_fixture_name: nil,
    fixture_overrides: {},
    with_block: nil
  )
    prefix = SiteSetting.discourse_newsletter_integration_mailchimp_server_prefix

    url = "https://#{prefix}.api.mailchimp.com/#{path}"
    auth_header = "Basic #{SiteSetting.discourse_newsletter_integration_mailchimp_api_key}"
    response_body =
      (
        if response_fixture_name
          newsletter_integration_fixture("mailchimp/#{response_fixture_name}.json")
        else
          ""
        end
      )

    if response_body.present? && fixture_overrides.present?
      response_body = JSON.parse(response_body).deep_merge(fixture_overrides).to_json
    end

    with_args = {
      headers: {
        "Content-Type" => "application/json",
        "Authorization" => auth_header,
      },
    }
    with_args[:body] = request_body if request_body
    stub_request(verb, url).with(**with_args, &with_block).to_return(
      status: status,
      body: response_body,
    )
  end

  def newsletter_integration_fixture(name)
    path = File.expand_path("../fixtures/#{name}", __dir__)
    File.read(path)
  end

  def configure_listmonk_settings
    SiteSetting.discourse_newsletter_integration_enabled = true
    SiteSetting.discourse_newsletter_integration_provider = "listmonk"
    SiteSetting.discourse_newsletter_integration_listmonk_url = "https://listmonk.example.com/"
    SiteSetting.discourse_newsletter_integration_listmonk_api_username = "discourse"
    SiteSetting.discourse_newsletter_integration_listmonk_api_token = ("a" * 48)
    SiteSetting.discourse_newsletter_integration_listmonk_list_id = 42
    SiteSetting.discourse_newsletter_integration_listmonk_preconfirm_subscriptions = true
  end

  def stub_listmonk_subscriber_lookup(user, results: [], status: 200, timeout: false)
    query =
      URI.encode_www_form(
        query: "subscribers.email = '#{user.email.downcase.gsub("'", "''")}'",
        per_page: 1,
      )
    setup_listmonk_stub(
      :get,
      "api/subscribers?#{query}",
      status: status,
      timeout: timeout,
      response_body: {
        data: {
          results: results,
        },
      },
    )
  end

  def listmonk_headers
    {
      "Authorization" =>
        "Basic #{Base64.strict_encode64("#{SiteSetting.discourse_newsletter_integration_listmonk_api_username}:#{SiteSetting.discourse_newsletter_integration_listmonk_api_token}")}",
      "Content-Type" => "application/json",
    }
  end

  def setup_listmonk_stub(
    verb,
    path,
    request_body: nil,
    response_body: { data: true },
    status: 200,
    timeout: false
  )
    url = SiteSetting.discourse_newsletter_integration_listmonk_url.chomp("/")
    args = { headers: listmonk_headers }
    args[:body] = request_body if request_body
    stub = stub_request(verb, "#{url}/#{path}").with(**args)
    return stub.to_timeout if timeout

    stub.to_return(status: status, body: response_body.to_json)
  end
end
