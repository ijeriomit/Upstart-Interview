import { action } from '@ember/object';
import Route from '@ember/routing/route';
import { service } from '@ember/service';
import { SessionChangedError } from '../services/accounts-api';

export default class ApplicationRoute extends Route {
  @service accountsApi;

  beforeModel() {
    return this.accountsApi.getCurrentUser();
  }

  @action
  error(error) {
    // The session change owns navigation. Ignore obsolete route requests.
    return !(error instanceof SessionChangedError);
  }
}
