import Route from '@ember/routing/route';
import { service } from '@ember/service';

/** AdminGamesRoute loads one page of games. */
export default class AdminGamesIndexRoute extends Route {
  @service api;

  queryParams = {
    page: { refreshModel: true },
    q: { refreshModel: true },
    active: { refreshModel: true },
  };

  async model({ page, q, active }) {
    const { data, meta } = await this.api.requestWithMeta('/admin/games', {
      query: { page, q, active },
    });
    return { games: data, meta };
  }
}
