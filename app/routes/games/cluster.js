import Route from '@ember/routing/route';
import { service } from '@ember/service';

/**
 * GamesClusterRoute loads a game's map as its game master sees it.
 *
 * One request carries every state the page branches on: whether the game has
 * been set up, whether it already has a cluster, and — when one could be
 * generated — the settings and bounds the form works inside. Asking for those
 * separately would let the page render a form built from one moment's answer
 * and submit it against another's.
 *
 * There is no game-master check here, and there must not be one. The endpoint
 * is the game master's, so a player at the same table is answered 403 and an
 * account with no seat is answered 404, both of which the error route renders.
 * A guard could only repeat what the server already refuses, and would be wrong
 * the moment a seat changed.
 */
export default class GamesClusterRoute extends Route {
  @service api;

  async model({ game_id: gameId }) {
    return this.api.get(`/games/${gameId}/cluster`);
  }
}
