import Component from "@glimmer/component";
import { service } from "@ember/service";
import PreferenceCheckbox from "discourse/components/preference-checkbox";
import { i18n } from "discourse-i18n";

export default class SubscribeNewsletterSection extends Component {
  @service site;

  get showSubscribeSection() {
    return this.site.newsletter_integration_plugin_configured;
  }

  <template>
    {{#if this.showSubscribeSection}}
      <div class="control-group newsletter-integration-subscribe-section">
        <label class="control-label">{{i18n
            "discourse_newsletter_integration.preferences.section_head"
          }}</label>
        <PreferenceCheckbox
          @labelKey="discourse_newsletter_integration.preferences.checkbox_description"
          @checked={{@outletArgs.model.newsletter_integration_subscribe_global_newsletter}}
          class="subscribe-checkbox"
        />
      </div>
    {{/if}}
  </template>
}
