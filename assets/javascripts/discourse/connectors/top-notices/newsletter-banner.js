import Component from "@glimmer/component";
import { tracked } from "@glimmer/tracking";
import { action } from "@ember/object";
import { service } from "@ember/service";
import { ajax } from "discourse/lib/ajax";
import { popupAjaxError } from "discourse/lib/ajax-error";

export default class NewsletterBanner extends Component {
  @service site;
  @service currentUser;

  @tracked disableControls = false;
  @tracked dismissed = false;
  @tracked subscribed = false;

  get showBanner() {
    return (
      this.site.newsletter_integration_plugin_configured &&
      this.currentUser?.show_newsletter_subscription_banner &&
      !this.dismissed
    );
  }

  @action
  async subscribe() {
    this.disableControls = true;

    try {
      await ajax("/newsletter-integration/subscriptions", { type: "POST" });
      this.subscribed = true;
    } catch (e) {
      popupAjaxError(e);
    }

    this.disableControls = false;
  }

  @action
  async dismiss() {
    this.dismissed = true;
    if (!this.subscribed) {
      try {
        await ajax("/newsletter-integration/subscriptions", { type: "DELETE" });
      } catch (e) {
        this.dismissed = false;
        popupAjaxError(e);
      }
    }
  }
}
