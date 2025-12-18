import Component from "@glimmer/component";
import { on } from "@ember/modifier";
import { action } from "@ember/object";
import { service } from "@ember/service";
import { i18n } from "discourse-i18n";

export default class SubscribeNewsletterSection extends Component {
  @service site;

  get showSubscribeSection() {
    return this.site.newsletter_integration_plugin_configured;
  }

  @action
  updateSubscription(event) {
    this.args.outletArgs.model.set(
      "newsletter_integration_subscribe_global_newsletter",
      event.target.checked
    );
  }

  <template>
    {{#if this.showSubscribeSection}}
      <div class="control-group newsletter-integration-subscribe-section">
        <label class="control-label">{{i18n
            "discourse_newsletter_integration.preferences.section_head"
          }}</label>
        <div class="controls subscribe-checkbox">
          <label class="checkbox-label">
            <input
              type="checkbox"
              checked={{@outletArgs.model.newsletter_integration_subscribe_global_newsletter}}
              {{on "change" this.updateSubscription}}
            />
            {{i18n
              "discourse_newsletter_integration.preferences.checkbox_description"
            }}
          </label>
        </div>
      </div>
    {{/if}}
  </template>
}
