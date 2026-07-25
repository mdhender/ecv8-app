import { ProtectedRoute } from 'ec/utils/routes';
import { service } from '@ember/service';

/**
 * ProfileRoute loads the account from the API rather than reading the copy in
 * the session, so an edit made in another tab is reflected on reload.
 */
export default class ProfileRoute extends ProtectedRoute {
  @service api;

  async model() {
    return { account: await this.api.get('/me') };
  }
}
