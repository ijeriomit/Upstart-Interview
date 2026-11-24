import { action } from '@ember/object';
import Route from '@ember/routing/route';
import { service } from '@ember/service';
import { SessionChangedError } from '../services/user-api';

export default class ApplicationRoute extends Route {
  @service userApi;

  beforeModel() {
    return this.userApi.getCurrentUser();
  }

  @action
  error(error) {
    // The session change owns navigation. Ignore obsolete route requests.
    return !(error instanceof SessionChangedError);
  }
}
