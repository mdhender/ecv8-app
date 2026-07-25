import Route from '@ember/routing/route';
import { service } from '@ember/service';

/**
 * ApplicationRoute restores the session before anything else renders.
 *
 * Ember Simple Auth requires `session.setup()` to be awaited here: it runs the
 * session store's `restore`, which asks the API whether the browser's cookie
 * still identifies a live session. Without it every route would start out
 * looking signed-out and a reload would bounce the user to /login.
 */
export default class ApplicationRoute extends Route {
  @service session;

  async beforeModel() {
    await this.session.setup();
  }
}
