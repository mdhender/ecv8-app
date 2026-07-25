import BaseStore from 'ember-simple-auth/session-stores/base';
import { service } from '@ember/service';
import { ApiError } from 'ec/services/api';

/**
 * ServerSessionStore keeps no session state in the browser at all.
 *
 * Ember Simple Auth's bundled stores persist the session in localStorage, a
 * cookie, or memory. None of those fit here: the real credential is an HttpOnly
 * cookie that JavaScript cannot read, and a copy of the session in localStorage
 * would be an unnecessary second place for it to leak from.
 *
 * Instead the server is the store. `restore` asks the API who the current
 * session belongs to, which is exactly the question a store answers on page
 * load. If the cookie is valid the API describes the session; if not it answers
 * 401 and this resolves with `{}`, which Ember Simple Auth reads as
 * unauthenticated.
 *
 * Consequences worth knowing:
 *
 *   - `persist` is a no-op. The server already recorded the session when it set
 *     the cookie, and there is nothing on the client to write.
 *   - `clear` is a no-op for the same reason; the authenticator's `invalidate`
 *     is what asks the server to revoke the session and expire the cookie.
 *   - Cross-tab synchronisation is not automatic, because there is no storage
 *     event to listen for. A second tab notices a sign-out on its next
 *     navigation or reload, when `restore` runs again.
 */
export default class ApplicationSessionStore extends BaseStore {
  @service api;

  /**
   * Names this store for Ember Simple Auth, which derives the sessionStorage
   * key for the post-login redirect target from it.
   */
  key = 'ec-session';

  /** No-op: the server holds the session; the browser holds only a cookie. */
  async persist() {}

  /**
   * Asks the API to describe the session the cookie identifies.
   *
   * Resolving with a populated `authenticated` object makes the session
   * authenticated; resolving with `{}` leaves it unauthenticated. A network
   * failure also resolves with `{}` rather than rejecting, so a transient
   * outage presents as signed-out instead of wedging application boot.
   */
  async restore() {
    try {
      const session = await this.api.get('/session');
      return {
        authenticated: {
          authenticator: 'authenticator:cookie',
          ...session,
        },
      };
    } catch (error) {
      if (error instanceof ApiError && error.isUnauthorized) {
        return {};
      }
      return {};
    }
  }

  /** No-op: there is nothing stored on the client to clear. */
  async clear() {}

  /**
   * The redirect target is a path, not a secret, and it must survive the
   * navigation to the login page. Ember Simple Auth's session service keeps it
   * in sessionStorage under a key derived from `key` above, so this store opts
   * out of persisting a second copy.
   */
  setRedirectTarget = null;
  getRedirectTarget = null;
  clearRedirectTarget = null;
}
