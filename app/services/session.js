import ESASessionService from 'ember-simple-auth/services/session';
import { service } from '@ember/service';

/**
 * Returns `path` if it is a safe same-origin destination, otherwise null.
 *
 * The post-login redirect target comes from sessionStorage, which any script on
 * the page could have written, so it is treated as untrusted input. Only a
 * root-relative path is accepted:
 *
 *   - `//evil.example.com` is protocol-relative and would leave the site.
 *   - `https://evil.example.com` is absolute and would leave the site.
 *   - `\\evil.example.com` is normalised to `//` by some browsers.
 *   - anything not starting with `/` is not a destination we produced.
 *
 * Parsing against a throwaway origin catches encoded variants that a string
 * check alone would miss.
 */
export function safeRedirectPath(path) {
  if (typeof path !== 'string' || path === '') {
    return null;
  }
  if (
    !path.startsWith('/') ||
    path.startsWith('//') ||
    path.startsWith('/\\')
  ) {
    return null;
  }
  try {
    const base = 'https://ecv8.invalid';
    const url = new URL(path, base);
    if (url.origin !== base) {
      return null;
    }
    return `${url.pathname}${url.search}${url.hash}`;
  } catch {
    return null;
  }
}

/**
 * SessionService adds ECV8's notion of "who is signed in" to Ember Simple
 * Auth's session, and makes the post-login redirect safe.
 *
 * None of this is a security boundary. The server authorises every request on
 * its own; `isAdmin` here only decides what the interface offers.
 */
export default class SessionService extends ESASessionService {
  @service router;

  /** The account the session is acting as, or null when signed out. */
  get account() {
    return this.data?.authenticated?.account ?? null;
  }

  /** True when this session may use administrator features. */
  get isAdmin() {
    return this.data?.authenticated?.is_admin === true;
  }

  /** True while an administrator is acting as another account. */
  get isImpersonating() {
    return this.data?.authenticated?.impersonating === true;
  }

  /** The real administrator behind an impersonated session, or null. */
  get impersonator() {
    return this.data?.authenticated?.impersonator ?? null;
  }

  /**
   * Re-reads the session from the server after an operation that changed it
   * without re-authenticating — starting or stopping impersonation, or editing
   * the signed-in account's own profile.
   *
   * The session data cannot simply be assigned: `authenticated` is a reserved
   * key that Ember Simple Auth refuses to let anything but an authenticator
   * write. Asking the internal session to restore is the supported route, and
   * it happens to be the honest one here — the store's `restore` re-reads
   * `/session`, so the client ends up with whatever the server actually thinks
   * rather than a locally patched copy.
   */
  async refresh() {
    await this.session.restore();
  }

  /**
   * Sends the user where they were originally headed, once signed in.
   *
   * This overrides Ember Simple Auth's version to run the stored destination
   * through safeRedirectPath first. An attempted transition is preferred when
   * one exists, since it is an in-memory Transition the router produced rather
   * than a string from storage.
   */
  handleAuthentication(routeAfterAuthentication) {
    const target = this.getRedirectTarget();
    this.clearRedirectTarget();

    const attempted = this.attemptedTransition;
    if (attempted) {
      this.attemptedTransition = null;
      attempted.retry();
      return;
    }

    const safe = safeRedirectPath(target);
    if (safe) {
      this.router.transitionTo(safe);
      return;
    }
    this.router.transitionTo(routeAfterAuthentication);
  }
}
