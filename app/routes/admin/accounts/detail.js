import Route from '@ember/routing/route';
import { service } from '@ember/service';

/** AdminAccountsDetailRoute loads one account for editing. */
export default class AdminAccountsDetailRoute extends Route {
  @service api;

  async model({ account_id: accountId }) {
    return { account: await this.api.get(`/admin/accounts/${accountId}`) };
  }
}
