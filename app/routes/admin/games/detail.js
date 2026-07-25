import Route from '@ember/routing/route';
import { service } from '@ember/service';

/**
 * AdminGamesDetailRoute loads a game with its memberships and the accounts that
 * could be added to it.
 *
 * The three requests are issued together because none depends on another and
 * the page is not useful until all have arrived. Only user accounts are
 * requested for the picker: the server refuses to put an admin in a game, so
 * offering one would only produce an error.
 */
export default class AdminGamesDetailRoute extends Route {
  @service api;

  async model({ game_id: gameId }) {
    const [game, memberships, candidates] = await Promise.all([
      this.api.get(`/admin/games/${gameId}`),
      this.api.get(`/admin/games/${gameId}/memberships`),
      this.api.requestWithMeta('/admin/accounts', {
        query: { role: 'user', active: 'true', per_page: 100 },
      }),
    ]);
    return { game, memberships, candidates: candidates.data };
  }
}
