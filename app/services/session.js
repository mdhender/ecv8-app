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
   * Reconciles the client with the server after a request was refused for want
   * of a session.
   *
   * A session can end while the page is open — it expires, or an administrator
   * revokes it — and nothing announces that here: the cookie is `HttpOnly`, so
   * its lifetime is invisible to JavaScript. Until something corrects it the
   * client goes on believing it is signed in, which is worse than being signed
   * out: guards let every transition through, each model hook fails with 401,
   * and the sign-in link on the error page bounces straight back to the
   * dashboard because `/login` turns authenticated visitors away.
   *
   * This re-reads rather than clearing locally, so the server remains the only
   * authority on whether a session exists. A 401 from one endpoint is a reason
   * to ask the question again, not an answer in itself; `restore` asks
   * `/session` and rejects only once the server has said there is nothing there,
   * having already marked the session unauthenticated.
   */
  async expire() {
    if (!this.isAuthenticated) {
      return;
    }
    try {
      await this.refresh();
    } catch {
      // `restore` rejects when the server no longer knows the session. The
      // internal session cleared itself on the way out; there is nothing left
      // to undo, and nothing here that a caller could act on.
    }
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
