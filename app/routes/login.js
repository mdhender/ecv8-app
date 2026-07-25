import Route from '@ember/routing/route';
import { service } from '@ember/service';

/**
 * LoginRoute keeps signed-in users off the sign-in form.
 *
 * Landing on /login while already authenticated is almost always a stale
 * bookmark, so it redirects rather than offering a form that would replace a
 * perfectly good session.
 */
export default class LoginRoute extends Route {
  @service session;

  beforeModel() {
    this.session.prohibitAuthentication('dashboard');
  }
}
