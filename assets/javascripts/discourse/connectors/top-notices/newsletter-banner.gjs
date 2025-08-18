import Component from "@glimmer/component";
import { tracked } from "@glimmer/tracking";
import { action } from "@ember/object";
import { service } from "@ember/service";
import DButton from "discourse/components/d-button";
import emoji from "discourse/helpers/emoji";
import getUrl from "discourse/helpers/get-url";
import htmlSafe from "discourse/helpers/html-safe";
import { ajax } from "discourse/lib/ajax";
import { popupAjaxError } from "discourse/lib/ajax-error";
import { i18n } from "discourse-i18n";

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

  <template>
    {{#if this.showBanner}}
      <aside class="newsletter-subscription-banner">
        <div class="banner-text">
          {{#if this.subscribed}}
            <h3>{{i18n "discourse_newsletter_integration.banner.thank_you"}}
              {{emoji "tada"}}</h3>
            <p class="banner-description">
              {{htmlSafe
                (i18n
                  "discourse_newsletter_integration.banner.added_to_newsletter"
                  preferencesUrl=(getUrl "/my/preferences/emails")
                )
              }}
            </p>
          {{else}}
            <h2>{{i18n "discourse_newsletter_integration.banner.heading"}}
              {{emoji "love_letter"}}</h2>
            <p class="banner-description">
              {{i18n "discourse_newsletter_integration.banner.description"}}
            </p>
          {{/if}}
        </div>
        <div class="banner-controls">
          <DButton @icon="xmark" @action={{this.dismiss}} class="close-btn" />
          {{#unless this.subscribed}}
            <DButton
              @label="discourse_newsletter_integration.banner.subscribe"
              @action={{this.subscribe}}
              @disabled={{this.disableControls}}
              class="btn-primary subscribe-btn"
            />
          {{/unless}}
        </div>
      </aside>
    {{/if}}
  </template>
}
