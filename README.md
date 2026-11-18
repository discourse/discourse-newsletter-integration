# Discourse Newsletter Integration Plugin

This Discourse plugin integrates newsletter services with your Discourse forum, allowing users to subscribe and unsubscribe from a newsletter. The newsletter is synced with a mailing list in the supported newsletter provider, and users can manage their subscription preferences directly from Discourse.

The plugin supports Mailchimp and listmonk as newsletter providers, with one global newsletter for all users. Newsletters limited to groups are not currently supported.

## Features

1. Admins can configure a global newsletter that will be synced with a mailing list in the supported newsletter provider.
2. Users will see a dismissible banner about the newsletter, allowing them to subscribe or dismiss the banner.
3. Once the banner is dismissed, it won't appear again for the user.
4. A checkbox is added to the user preferences page (`/my/preferences/emails`), allowing users to change their subscription at any time.
5. Subscribers are added or removed from the linked mailing list in the supported newsletter provider via their API when users subscribe or unsubscribe.
6. With Mailchimp, if a user subscribes or unsubscribes from the linked mailing list outside of Discourse (e.g., via an unsubscribe link in an email footer), their subscription state will be updated in Discourse to reflect the new state in the newsletter provider. This is done by setting up a webhook on the provider's end that notifies Discourse of changes made to the subscribers list.

## Installation

To install the Discourse Newsletter Integration Plugin, follow the [standard plugin installation instructions](https://meta.discourse.org/t/install-plugins-in-discourse/19157).

## Configuration

See instructions here: https://meta.discourse.org/t/discourse-newsletter-integration/275509.

## Contributing

If you'd like to contribute to the development of this plugin, please fork the repository and submit a pull request on GitHub.

## License

This Discourse Newsletter Integration Plugin is released under the MIT License.

## listmonk provider

listmonk is available as an alternative newsletter provider. Select `listmonk` in the `discourse_newsletter_integration_provider` site setting, then configure:

- `discourse_newsletter_integration_listmonk_url` — base URL of the listmonk instance (for example `https://listmonk.example.com`).
- `discourse_newsletter_integration_listmonk_api_username` — listmonk API username.
- `discourse_newsletter_integration_listmonk_api_token` — listmonk API token.
- `discourse_newsletter_integration_listmonk_list_id` — numeric listmonk list ID.
- `discourse_newsletter_integration_listmonk_preconfirm_subscriptions` — when enabled, Discourse subscriptions are immediately confirmed. Disable it to use listmonk double opt-in.

The base URL must use HTTP or HTTPS and must not contain credentials, a query string, or a fragment. Optional ports and subpaths are supported. API usernames use listmonk’s letters, digits, `_`, `-`, `.`, and `@` format (at least three characters); generated API tokens contain 48 alphanumeric characters. Empty settings are allowed while the provider is not configured.

Outbound requests use Discourse’s `FinalDestination::HTTP` SSRF protection.

The provider creates subscribers when necessary, adds existing subscribers to the configured list, and marks the list membership as unsubscribed when a user opts out in Discourse. Mailchimp remains the default provider for backward compatibility.

The listmonk integration synchronizes subscription changes from Discourse to listmonk only. Changes made directly in listmonk, including email unsubscribe links and double opt-in confirmation, are not synchronized back to Discourse.


### Tested listmonk versions

Compatibility checks were performed on **listmonk v6.2.0 and v7.0.0-beta.2** on November 14, 2026, using local Docker containers (Linux ARM64) and PostgreSQL 17.6.

- API authentication and subscriber/list/campaign reads worked on both versions, including after upgrading the same database from v6.2.0 to v7.0.0-beta.2 and restarting it.
- On v7.0.0-beta.2, the provider's exact API requests were replayed successfully for subscriber lookup and creation, subscription, resubscription, and unsubscription from the target list without affecting another list. Setting an existing subscription to `unconfirmed` also passed.
- Migration checks preserved multiple lists, subscribers, subscription statuses, campaigns, templates, users, and roles. The same API token and administrator TOTP secret continued to work after migration.

The API user needs subscriber read/manage permissions, `subscribers:sql_query` for the provider's email lookup, and permission to manage the target list.

These checks used synthetic data and direct HTTP requests, not a full Discourse end-to-end test. Actual SMTP delivery and double opt-in email delivery were not tested. The v7 result applies specifically to **v7.0.0-beta.2**, not to every v7 beta or future release.

### listmonk reliability and double opt-in

The listmonk client uses a 5 second connection timeout and a 15 second read timeout so a failing listmonk instance does not leave a Sidekiq worker blocked indefinitely.

When `discourse_newsletter_integration_listmonk_preconfirm_subscriptions` is disabled, new subscribers are created without preconfirmation. For an existing subscriber, the plugin adds the subscriber to the configured list as `unconfirmed` and then calls listmonk's `/api/subscribers/{id}/optin` endpoint to request the confirmation email. Whether an opt-in email is required depends on the list's opt-in configuration in listmonk.
