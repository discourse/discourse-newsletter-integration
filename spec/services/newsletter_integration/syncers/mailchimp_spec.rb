# frozen_string_literal: true

describe NewsletterIntegration::Syncers::Mailchimp do
  include_context "subscription syncers common spec", provider: :mailchimp
end
