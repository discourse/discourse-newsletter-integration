# frozen_string_literal: true

require "rails_helper"
require_relative "./support/newsletter_integration_helpers"
require_relative "./support/syncers_shared_examples"

RSpec.configure { |c| c.include NewsletterIntegrationHelpers }
