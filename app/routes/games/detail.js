import Route from '@ember/routing/route';
import { service } from '@ember/service';

/**
 * GamesDetailRoute loads one game as the account seated at it sees it.
 *
 * One request carries everything the page branches on: the game, whether this
 * account is its game master, its state, and — for the game master of a game
 * with no state — the seed values the setup form starts from. Asking for the
 * state separately would mean the page could render a game master's form from
 * one moment's answer and a player's message from another's.
 *
 * A game this account has no seat at answers 404, which the error route renders.
 * That is the server's decision and the only one that matters; nothing here
 * checks it first.
 */
export default class GamesDetailRoute extends Route {
  @service api;

  async model({ game_id: gameId }) {
    return { game: await this.api.get(`/games/${gameId}`) };
  }
}
