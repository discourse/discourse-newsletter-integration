import { click, visit } from "@ember/test-helpers";
import { test } from "qunit";
import pretender from "discourse/tests/helpers/create-pretender";
import {
  acceptance,
  exists,
  query,
  updateCurrentUser,
} from "discourse/tests/helpers/qunit-helpers";
import { i18n } from "discourse-i18n";

acceptance(
  "Discourse Newsletter Integration - Newsletter Banner - Anons",
  function (needs) {
    needs.site({
      newsletter_integration_plugin_configured: true,
    });

    test("banner visibility", async function (assert) {
      await visit("/");

      assert.notOk(
        exists(".newsletter-subscription-banner"),
        "banner is not visible to anons"
      );
    });
  }
);

acceptance(
  "Discourse Newsletter Integration - Newsletter Banner - Logged in users",
  function (needs) {
    needs.user({
      show_newsletter_subscription_banner: true,
    });

    needs.site({
      newsletter_integration_plugin_configured: true,
    });

    test("when show_newsletter_subscription_banner User property is true", async function (assert) {
      updateCurrentUser({
        show_newsletter_subscription_banner: true,
      });

      await visit("/");

      assert.ok(exists(".newsletter-subscription-banner"), "banner is visible");
    });

    test("when show_newsletter_subscription_banner User property is false", async function (assert) {
      updateCurrentUser({
        show_newsletter_subscription_banner: false,
      });

      await visit("/");

      assert.notOk(
        exists(".newsletter-subscription-banner"),
        "banner is not visible"
      );
    });

    test("dismiss button when clicked and the HTTP request succeeds", async function (assert) {
      let deleteRequestSent = false;

      pretender.delete("/newsletter-integration/subscriptions", () => {
        deleteRequestSent = true;
        return [200, {}, ""];
      });

      await visit("/");
      await click(".newsletter-subscription-banner .close-btn");

      assert.ok(
        deleteRequestSent,
        "sends a HTTP request to persist the banner dismissed state"
      );
      assert.notOk(
        exists(".newsletter-subscription-banner"),
        "banner is no longer visible"
      );
    });

    test("dismiss button when clicked but the HTTP request fails", async function (assert) {
      pretender.delete("/newsletter-integration/subscriptions", () => {
        return [403, {}, { error: "something went wrong" }];
      });

      await visit("/");
      await click(".newsletter-subscription-banner .close-btn");

      assert.ok(
        exists(".newsletter-subscription-banner"),
        "banner remains visible"
      );
      assert.strictEqual(
        query("#dialog-holder .dialog-body").textContent.trim(),
        "something went wrong",
        "a popup appears with the error message from the server"
      );
    });

    test("subscribe button when clicked and the HTTP request succeeds", async function (assert) {
      let postRequestSent = false;

      pretender.post("/newsletter-integration/subscriptions", () => {
        postRequestSent = true;
        return [200, {}, ""];
      });

      await visit("/");

      assert
        .dom(".newsletter-subscription-banner .banner-text")
        .includesText(
          i18n("discourse_newsletter_integration.banner.heading"),
          "banner has text to prompt the user to subscribe"
        );

      await click(".newsletter-subscription-banner .subscribe-btn");

      assert.ok(postRequestSent, "sends a HTTP request to subscribe the user");
      assert
        .dom(".newsletter-subscription-banner .banner-text")
        .includesText(
          i18n("discourse_newsletter_integration.banner.thank_you"),
          "banner displays a message to indicate that the user has been subscribed"
        );

      const preferencesLink = query(
        ".newsletter-subscription-banner .banner-description a"
      );
      assert.ok(
        preferencesLink.href.endsWith("/my/preferences/emails"),
        "there's a link to preferences"
      );

      await click(".newsletter-subscription-banner .close-btn");

      assert
        .dom(".newsletter-subscription-banner")
        .doesNotExist("clicking the dismiss closes the banner");
    });

    test("subscribe button when clicked but the HTTP request fails", async function (assert) {
      pretender.post("/newsletter-integration/subscriptions", () => {
        return [429, {}, { error: "chill bro you did this too many times" }];
      });

      await visit("/");
      await click(".newsletter-subscription-banner .subscribe-btn");

      assert.ok(
        exists(".newsletter-subscription-banner"),
        "banner remains visible"
      );
      assert.strictEqual(
        query("#dialog-holder .dialog-body").textContent.trim(),
        "chill bro you did this too many times",
        "a popup appears with the error message from the server"
      );
    });
  }
);
