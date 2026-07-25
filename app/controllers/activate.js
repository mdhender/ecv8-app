import Controller from '@ember/controller';

/**
 * A controller exists here only because Ember still requires one to declare
 * query parameters: a route's `queryParams` hash configures behaviour such as
 * refreshModel, but the binding itself is declared on the controller. Nothing
 * else in this application uses controllers.
 */
export default class ActivateController extends Controller {
  queryParams = ['token'];

  token = null;
}
