import Component from "@glimmer/component";
import { service } from "@ember/service";

export default class SubscribeNewsletterSection extends Component {
  @service site;

  get showSubscribeSection() {
    return this.site.newsletter_integration_plugin_configured;
  }
}
