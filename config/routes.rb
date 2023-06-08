# frozen_string_literal: true

NewsletterIntegration::Engine.routes.draw do
  post "/subscriptions" => "newsletter_subscription#subscribe"
  delete "/subscriptions" => "newsletter_subscription#unsubscribe"

  namespace :webhooks do
    get "/mailchimp/:secret" => "mailchimp#verify", :constraints => { secret: /\h{32}/ }
    post "/mailchimp/:secret" => "mailchimp#sync", :constraints => { secret: /\h{32}/ }
  end
end
