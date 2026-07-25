import Route from '@ember/routing/route';
import { service } from '@ember/service';

/**
 * GamesIndexRoute loads the games the signed-in account is seated at.
 *
 * It reads the same endpoint the dashboard does, because the answer to "which
 * games am I in?" is one answer and giving it two sources would let the two
 * disagree. What differs is the page around it: this one exists to be linked
 * to and to hold the detail route's outlet.
 */
export default class GamesIndexRoute extends Route {
  @service api;

  async model() {
    return { memberships: await this.api.get('/me/games') };
  }
}
