import Service from '@ember/service';
import { tracked } from '@glimmer/tracking';

/**
 * ActivationLinksService holds the most recently minted magic link.
 *
 * The API returns an activation URL exactly once, because only its hash is
 * stored and the application does not send email. That makes the link the most
 * perishable thing in the interface: if it disappears before the administrator
 * copies it, the only remedy is to reissue.
 *
 * It cannot live in the form that created it. Refreshing the route to pick up
 * the new account swaps in the loading template, which tears down the form and
 * everything it was rendering. Keeping the link in a service puts it outside
 * that lifecycle, so it survives the refresh and stays on screen until it is
 * explicitly dismissed.
 */
export default class ActivationLinksService extends Service {
  @tracked latest = null;

  /** Records a newly issued link so the banner can display it. */
  remember(link) {
    this.latest = link;
  }

  /** Clears the banner once the administrator has copied the link. */
  dismiss() {
    this.latest = null;
  }
}
