import EmberRouter from '@embroider/router';
import config from 'ec/config/environment';

export default class Router extends EmberRouter {
  location = config.locationType;
  rootURL = config.rootURL;
}

Router.map(function () {
  this.route('login');
  this.route('activate');
  this.route('dashboard');
  this.route('profile');

  // A game gets its own URL for the same reason an account does: it is a place
  // a player returns to, reloads, and links to, not a panel inside a list.
  this.route('games', function () {
    this.route('detail', { path: '/:game_id' });
    // A sibling of detail rather than a child of it, because the map is a page
    // of its own — a game master returns to it, and a hundred stelliums is not
    // a panel to hang off the page a game is started from.
    this.route('cluster', { path: '/:game_id/cluster' });
  });

  this.route('admin', function () {
    // Nested detail routes so an account or a game has its own URL an
    // administrator can link to, reload, and use the back button with.
    this.route('accounts', function () {
      this.route('detail', { path: '/:account_id' });
    });
    this.route('games', function () {
      this.route('detail', { path: '/:game_id' });
    });
  });
});
