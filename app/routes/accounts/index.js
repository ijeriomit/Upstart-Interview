import Route from '@ember/routing/route';
import { service } from '@ember/service';

export default class AccountsIndexRoute extends Route {
  @service accountsApi;

  model() {
    return this.accountsApi.getAccounts();
  }
}
