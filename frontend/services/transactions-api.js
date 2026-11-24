import Service, { service } from '@ember/service';
import { normalizeAccountSummary } from '../serializers/accounts-api';

// Transaction writes return a full account summary. Store it immediately so
// the balance and transaction list update together.
export default class TransactionsApiService extends Service {
  @service accountsApi;
  @service store;
  @service userApi;

  async createTransaction(accountId, transaction) {
    // There is no server idempotency key in this API. If Rails commits but its
    // response is lost, retrying this POST can create a second transaction.
    // A production retry contract needs server-side deduplication; row locks
    // protect balance updates, not duplicate requests. Do not auto-retry here.
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
    // Invalidate in-flight reads before publishing the authoritative summary.
    // This counter does not order overlapping POST responses; server revisions
    // would be needed to reject an older write snapshot arriving afterward.
    this.accountsApi.noteWrite();
    return this.store.push(normalizeAccountSummary(summary));
  }
}
