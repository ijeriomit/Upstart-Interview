import Service, { service } from '@ember/service';
import { normalizeAccountSummary } from '../serializers/accounts-api';

// Transaction writes return a full account summary. Store it immediately so
// the balance and transaction list update together.
export default class TransactionsApiService extends Service {
  @service accountsApi;
  @service store;
  @service userApi;

  async createTransaction(accountId, transaction) {
    const identityVersion = this.userApi.identityVersion;
    const summary = await this.userApi.protectedRequest(
      identityVersion,
      '/accounts/' + encodeURIComponent(accountId) + '/transactions',
      {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ transaction }),
      },
    );
    this.userApi.assertIdentityVersion(identityVersion);
    this.accountsApi.noteWrite();
    return this.store.push(normalizeAccountSummary(summary));
  }
}
