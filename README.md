# Discourse Newsletter Integration Plugin

This Discourse plugin integrates newsletter services with your Discourse forum, allowing users to subscribe and unsubscribe from a newsletter. The newsletter is synced with a mailing list in the supported newsletter provider, and users can manage their subscription preferences directly from Discourse.

Currently, the plugin supports Mailchimp as the newsletter provider and only one global newsletter for all users. Support for additional providers and newsletters limited to groups is planned for future releases.

## Features

1. Admins can configure a global newsletter that will be synced with a mailing list in the supported newsletter provider.
2. Users will see a dismissible banner about the newsletter, allowing them to subscribe or dismiss the banner.
3. Once the banner is dismissed, it won't appear again for the user.
4. A checkbox is added to the user preferences page (`/my/preferences/emails`), allowing users to change their subscription at any time.
5. Subscribers are added or removed from the linked mailing list in the supported newsletter provider via their API when users subscribe or unsubscribe.
6. If a user subscribes or unsubscribes from the linked mailing list outside of Discourse (e.g., via an unsubscribe link in an email footer), their subscription state will be updated in Discourse to reflect the new state in the newsletter provider. This is done by setting up a webhook on the provider's end that notifies Discourse of changes made to the subscribers list.

## Installation

To install the Discourse Newsletter Integration Plugin, follow the [standard plugin installation instructions](https://meta.discourse.org/t/install-plugins-in-discourse/19157).

## Configuration

See instructions here: https://meta.discourse.org/t/discourse-newsletter-integration/275509.

## Contributing

If you'd like to contribute to the development of this plugin, please fork the repository and submit a pull request on GitHub.

## License

This Discourse Newsletter Integration Plugin is released under the MIT License.
