import { ProtectedRoute } from 'ec/utils/routes';
import { service } from '@ember/service';

/** DashboardRoute loads the games the signed-in account currently plays. */
export default class DashboardRoute extends ProtectedRoute {
  @service api;

  async model() {
    return { memberships: await this.api.get('/me/games') };
  }
}
