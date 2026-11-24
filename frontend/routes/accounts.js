import Route from '@ember/routing/route';
import { service } from '@ember/service';

export default class AccountsRoute extends Route {
  @service accountsApi;
  @service router;

  beforeModel() {
    if (!this.accountsApi.currentUser) this.router.replaceWith('sign-in');
  }

  // Route model hooks load data before their templates render. This parent
  // route stays active when navigating from the list into an account.
  model() {
    return this.accountsApi.currentUser;
  }
}
