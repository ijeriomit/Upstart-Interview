import Controller from '@ember/controller';
import { action } from '@ember/object';
import { service } from '@ember/service';

export default class AccountsShowController extends Controller {
  @service transactionsApi;

  @action
  recordTransaction(attributes) {
    return this.transactionsApi.createTransaction(this.model.id, attributes);
  }
}
