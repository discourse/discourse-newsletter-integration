import { withPluginApi } from "discourse/lib/plugin-api";

export default {
  name: "discourse-newsletter-integration-setup",

  initialize() {
    withPluginApi("1.6.0", (api) => {
      const currentUser = api.getCurrentUser();
      if (!currentUser) {
        return;
      }

      api.addSaveableUserField(
        "newsletter_integration_subscribe_global_newsletter"
      );

      api.addSaveAttributeToPreferencesController(
        "emails",
        "newsletter_integration_subscribe_global_newsletter"
      );
    });
  },
};
