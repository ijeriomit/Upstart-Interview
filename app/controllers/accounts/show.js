import Controller from '@ember/controller';
import { action } from '@ember/object';
import { service } from '@ember/service';

export default class AccountsShowController extends Controller {
  @service accountsApi;

  @action
  async recordTransaction(attributes) {
    const accountId = this.model.account.id;
    const summary = await this.accountsApi.createTransaction(
      accountId,
      attributes,
    );

    // Rails returns the updated summary. Replace the route model to rerender
    // the balance and history together without doing money math in the browser.
    if (this.model.account.id === accountId) {
      this.model = summary;
    }
  }
}
