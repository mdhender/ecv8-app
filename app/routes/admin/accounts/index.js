import Route from '@ember/routing/route';
import { service } from '@ember/service';

/**
 * AdminAccountsRoute loads one page of accounts.
 *
 * The filters are query parameters so a filtered list is a shareable URL and
 * survives a reload. refreshModel re-runs the server-side query rather than
 * filtering in the browser, which would only ever filter the current page.
 */
export default class AdminAccountsIndexRoute extends Route {
  @service api;

  queryParams = {
    page: { refreshModel: true },
    q: { refreshModel: true },
    role: { refreshModel: true },
    active: { refreshModel: true },
  };

  async model({ page, q, role, active }) {
    const { data, meta } = await this.api.requestWithMeta('/admin/accounts', {
      query: { page, q, role, active },
    });
    return { accounts: data, meta };
  }
}
