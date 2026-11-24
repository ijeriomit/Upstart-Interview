import Route from '@ember/routing/route';
import { service } from '@ember/service';

export default class SignInRoute extends Route {
  @service accountsApi;
  @service router;

  beforeModel() {
    if (this.accountsApi.currentUser) this.router.replaceWith('accounts.index');
  }
}
