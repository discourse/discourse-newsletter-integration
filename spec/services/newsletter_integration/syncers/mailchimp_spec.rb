# frozen_string_literal: true

require "rails_helper"

describe NewsletterIntegration::Syncers::Mailchimp do
  include_context "subscription syncers common spec", provider: :mailchimp
end
