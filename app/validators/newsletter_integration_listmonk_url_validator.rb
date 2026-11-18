# frozen_string_literal: true

class NewsletterIntegrationListmonkUrlValidator
  def initialize(opts = {})
  end

  def valid_value?(value)
    return true if value.empty?

    uri = URI.parse(value)
    uri.is_a?(URI::HTTP) && uri.host.present? && uri.userinfo.nil? && uri.query.nil? &&
      uri.fragment.nil? && uri.port.between?(1, 65_535)
  rescue URI::Error, ArgumentError
    false
  end

  def error_message
    I18n.t("site_settings.errors.newsletter_integration_listmonk_url_invalid")
  end
end
