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

      api.modifyClass("controller:preferences/emails", {
        pluginId: "discourse-newsletter-integration-emails-preference",

        init() {
          this._super(...arguments);
          this.saveAttrNames.push(
            "newsletter_integration_subscribe_global_newsletter"
          );
        },
      });
    });
  },
};
