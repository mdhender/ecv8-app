import Route from '@ember/routing/route';
import { service } from '@ember/service';

/** AdminIndexRoute has nothing of its own to show, so it opens accounts. */
export default class AdminIndexRoute extends Route {
  @service router;

  beforeModel() {
    this.router.replaceWith('admin.accounts');
  }
}
