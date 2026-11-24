import Controller from '@ember/controller';
import { action } from '@ember/object';
import { service } from '@ember/service';

export default class SignUpController extends Controller {
  @service accountsApi;
  @service router;

  @action
  async register({ user, accounts }) {
    await this.accountsApi.register({ user, accounts });
    return this.router.transitionTo('sign-in');
  }
}
