import { withPluginApi } from "discourse/lib/plugin-api";

export default {
  name: "discourse-newsletter-integration-setup",

  initialize() {
    withPluginApi((api) => {
      if (!api.getCurrentUser()) {
        return;
      }

      api.addSaveableUserField(
        "newsletter_integration_subscribe_global_newsletter",
        { page: "emails" }
      );
    });
  },
};
