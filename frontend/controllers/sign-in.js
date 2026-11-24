import Controller from '@ember/controller';
import { action } from '@ember/object';
import { service } from '@ember/service';

export default class SignInController extends Controller {
  @service userApi;

  @action
  signIn(credentials) {
    return this.userApi.signIn(credentials);
  }
}
