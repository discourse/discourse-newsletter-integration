# frozen_string_literal: true

# rubocop:disable RSpec/ContextWording
shared_context "subscription syncers common spec" do |provider:|
  # rubocop:enable RSpec/ContextWording
  fab!(:subscription) { Fabricate(:newsletter_user_subscription) }

  before { configure_required_settings }

  subject do
    described_class.new(
      user: subscription.user,
      newsletter_integration_id: subscription.newsletter_integration_id,
    )
  end

  describe "#sync" do
    it "sends a request to subscribe the user if the subscription is active" do
      subscription.update!(active: true)

      stub = setup_subscribe_request_stub(provider, subscription.user)
      subject.sync
      expect(stub).to have_been_requested
    end

    it "sends a request to unsubscribe the user if the subscription is inactive" do
      subscription.update!(active: false)

      stub = setup_unsubscribe_request_stub(provider, subscription.user)
      subject.sync
      expect(stub).to have_been_requested
    end
  end
end
