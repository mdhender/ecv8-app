import BaseAuthenticator from 'ember-simple-auth/authenticators/base';
import { service } from '@ember/service';
import { ApiError } from 'ec/services/api';

/**
 * CookieAuthenticator authenticates against the API's session endpoints.
 *
 * There is no token here. `authenticate` posts credentials and the server
 * replies with a Set-Cookie the browser stores and JavaScript cannot read; the
 * data resolved below is a description of the session, not a credential, and
 * exists so components can render the current account without a second request.
 */
export default class CookieAuthenticator extends BaseAuthenticator {
  @service api;

  /**
   * Confirms that data restored by the session store still represents a live
   * session.
   *
   * The store already asked the API, so a populated payload here means the
   * server said yes moments ago. Rejecting leaves the session unauthenticated.
   */
  async restore(data) {
    if (data?.authenticated === true) {
      return data;
    }
    throw new Error('no active session');
  }

  /**
   * Exchanges credentials for a session cookie.
   *
   * Rejects with the ApiError so the login form can show the server's own
   * message. That message is deliberately identical for a wrong password, an
   * unknown address, and a deactivated account.
   */
  async authenticate(email, password) {
    return this.api.post('/session', { email, password });
  }

  /**
   * Asks the server to revoke the session and expire the cookie.
   *
   * A failure is swallowed on purpose: if the server cannot be reached, or the
   * session was already revoked, the user still ends up signed out locally,
   * which is the safer outcome.
   */
  async invalidate() {
    try {
      await this.api.delete('/session');
    } catch (error) {
      if (!(error instanceof ApiError)) {
        throw error;
      }
    }
  }
}
