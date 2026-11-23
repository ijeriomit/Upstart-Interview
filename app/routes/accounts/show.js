import Route from '@ember/routing/route';
import { service } from '@ember/service';

export default class AccountsShowRoute extends Route {
  @service accountsApi;

  // The dynamic segment supplies account_id on first load and after reload.
  // The list links pass an ID, so Ember fetches this account's full summary.
  model({ account_id: accountId }) {
    return this.accountsApi.getAccount(accountId);
  }
}
