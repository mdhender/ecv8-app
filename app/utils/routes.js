import Route from '@ember/routing/route';
import { service } from '@ember/service';

/**
 * Base classes for guarded routes.
 *
 * These guards are a user-experience feature, not a security boundary. They
 * keep an anonymous visitor from seeing an empty page and keep admin links out
 * of a normal user's way. The server authorises every request independently, so
 * a user who defeats a guard still gets 401 or 403 from the API.
 */

/**
 * ProtectedRoute sends anonymous visitors to /login.
 *
 * Ember Simple Auth records the destination they asked for so they land there
 * after signing in rather than on a generic dashboard. That destination is
 * validated before use; see safeRedirectPath in the session service.
 */
export class ProtectedRoute extends Route {
  @service session;

  beforeModel(transition) {
    this.session.requireAuthentication(transition, 'login');
  }
}

/**
 * AdminRoute additionally sends non-administrators to their dashboard.
 *
 * An administrator who is impersonating someone counts as a non-administrator
 * here, matching the server, which refuses admin endpoints for the duration of
 * an impersonated session.
 */
export class AdminRoute extends ProtectedRoute {
  @service router;

  beforeModel(transition) {
    super.beforeModel(transition);
    if (this.session.isAuthenticated && !this.session.isAdmin) {
      this.router.replaceWith('dashboard');
    }
  }
}
