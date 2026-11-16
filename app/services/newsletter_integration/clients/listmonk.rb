# frozen_string_literal: true

module NewsletterIntegration
  module Clients
    class Listmonk
      class Error < StandardError
      end

      OPEN_TIMEOUT = 5
      READ_TIMEOUT = 15

      def initialize(base_url:, api_username:, api_token:)
        @base_url = base_url.to_s.sub(%r{/+\z}, "")
        @api_username = api_username
        @api_token = api_token
      end

      def request(verb:, path:, body: nil, query: nil)
        uri = URI("#{@base_url}/#{path.to_s.sub(%r{\A/+}, "")}")
        uri.query = URI.encode_www_form(query) if query.present?

        http = FinalDestination::HTTP.new(uri.host, uri.port)
        http.use_ssl = uri.scheme == "https"
        http.open_timeout = OPEN_TIMEOUT
        http.read_timeout = READ_TIMEOUT

        request = Net::HTTP.const_get(verb.to_s.capitalize).new(uri.request_uri)
        request.basic_auth(@api_username, @api_token)
        request["Content-Type"] = "application/json"
        request.body = body.to_json if body

        response = http.request(request)
        return response if response.is_a?(Net::HTTPSuccess)

        raise Error,
              "listmonk API returned HTTP #{response.code}: #{response.body.to_s.truncate(500)}"
      rescue Net::OpenTimeout, Net::ReadTimeout, Timeout::Error => e
        raise Error, "listmonk API request timed out: #{e.message}"
      rescue SocketError, Errno::ECONNREFUSED, Errno::ECONNRESET => e
        raise Error, "listmonk API connection failed: #{e.message}"
      end
    end
  end
end
