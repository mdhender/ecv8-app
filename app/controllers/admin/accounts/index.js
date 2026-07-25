import Controller from '@ember/controller';

/** Declares the account list's filters as query parameters. See activate.js. */
export default class AdminAccountsIndexController extends Controller {
  queryParams = ['page', 'q', 'role', 'active'];

  page = 1;
  q = '';
  role = '';
  active = '';
}
