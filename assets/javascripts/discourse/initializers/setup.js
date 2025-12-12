import { withPluginApi } from "discourse/lib/plugin-api";
import { VALUE_TRANSFORMERS } from "discourse/lib/transformer/registry";

export default {
  name: "discourse-newsletter-integration-setup",

  initialize() {
    withPluginApi((api) => {
      const currentUser = api.getCurrentUser();
      if (!currentUser) {
        return;
      }

      api.addSaveableUserField(
        "newsletter_integration_subscribe_global_newsletter"
      );

      if (VALUE_TRANSFORMERS.includes("preferences-save-attributes")) {
        api.registerValueTransformer(
          "preferences-save-attributes",
          ({ value: attrs, context }) => {
            if (context.page === "emails") {
              attrs.push("newsletter_integration_subscribe_global_newsletter");
            }
            return attrs;
          }
        );
      } else {
        // Backward compatibility for older Discourse versions
        api.modifyClass("controller:preferences/emails", {
          pluginId: "discourse-newsletter-integration-emails-preference",

          init() {
            this._super(...arguments);
            this.saveAttrNames.push(
              "newsletter_integration_subscribe_global_newsletter"
            );
          },
        });
      }
    });
  },
};
