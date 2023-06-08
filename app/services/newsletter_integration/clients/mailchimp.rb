# frozen_string_literal: true

module NewsletterIntegration
  module Clients
    class Mailchimp
      def initialize(server_prefix:, api_key:)
        @server_prefix = server_prefix
        @api_key = api_key
      end

      def request(verb:, path:, body: "")
        uri = URI("#{origin}#{path}")

        http = Net::HTTP.new(uri.host, uri.port)
        http.use_ssl = true

        request = Net::HTTP.const_get(verb.capitalize).new(uri.request_uri)
        request["Authorization"] = "Basic #{@api_key}"
        request["Content-Type"] = "application/json"
        request.body = body

        http.request(request)
      end

      private

      def origin
        "https://#{@server_prefix}.api.mailchimp.com/"
      end
    end
  end
end
