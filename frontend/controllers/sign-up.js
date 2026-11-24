import Controller from '@ember/controller';
import { action } from '@ember/object';
import { service } from '@ember/service';

export default class SignUpController extends Controller {
  @service userApi;
  @service router;

  @action
  async register({ user, accounts }) {
    await this.userApi.register({ user, accounts });
    return this.router.transitionTo('sign-in');
  }
}
