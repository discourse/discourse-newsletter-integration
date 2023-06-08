import Component from "@glimmer/component";
import { tracked } from "@glimmer/tracking";
import { action } from "@ember/object";
import { inject as service } from "@ember/service";
import { ajax } from "discourse/lib/ajax";
import { popupAjaxError } from "discourse/lib/ajax-error";

export default class NewsletterBanner extends Component {
  @service site;
  @service currentUser;
  @tracked disableControls = false;
  @tracked dismissed = false;

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

    let succeeded = true;
    try {
      await ajax("/newsletter-integration/subscriptions", { type: "POST" });
    } catch (e) {
      succeeded = false;
      popupAjaxError(e);
    }

    this.dismissed = succeeded;
    this.disableControls = false;
  }

  @action
  async dismiss() {
    this.dismissed = true;
    try {
      await ajax("/newsletter-integration/subscriptions", { type: "DELETE" });
    } catch (e) {
      this.dismissed = false;
      popupAjaxError(e);
    }
  }
}
