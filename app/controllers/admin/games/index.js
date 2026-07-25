import Controller from '@ember/controller';

/** Declares the game list's filters as query parameters. See activate.js. */
export default class AdminGamesIndexController extends Controller {
  queryParams = ['page', 'q', 'active'];

  page = 1;
  q = '';
  active = '';
}
