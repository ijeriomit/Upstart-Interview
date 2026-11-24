import Route from '@ember/routing/route';
import { service } from '@ember/service';

export default class SignUpRoute extends Route {
  @service userApi;
  @service router;

  beforeModel() {
    if (this.userApi.currentUser) this.router.replaceWith('accounts.index');
  }
}
