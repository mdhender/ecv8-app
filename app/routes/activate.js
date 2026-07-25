import Route from '@ember/routing/route';

/**
 * ActivateRoute reads the magic-link token out of the query string.
 *
 * The token arrives as ?token=... in the URL an administrator sent. It is
 * passed through to the model rather than stored anywhere, since it is
 * single-use and is spent the moment the form is submitted.
 */
export default class ActivateRoute extends Route {
  queryParams = {
    token: { refreshModel: true },
  };

  model({ token }) {
    return { token: token ?? '' };
  }
}
