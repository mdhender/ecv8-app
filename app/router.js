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
