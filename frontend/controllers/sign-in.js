import Controller from '@ember/controller';
import { action } from '@ember/object';
import { service } from '@ember/service';

export default class SignInController extends Controller {
  @service accountsApi;

  @action
  signIn(credentials) {
    return this.accountsApi.signIn(credentials);
  }
}
