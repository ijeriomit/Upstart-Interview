import Controller from '@ember/controller';
import { action } from '@ember/object';
import { service } from '@ember/service';

export default class AccountsShowController extends Controller {
  @service accountsApi;

  @action
  recordTransaction(attributes) {
    return this.accountsApi.createTransaction(this.model.id, attributes);
  }
}
