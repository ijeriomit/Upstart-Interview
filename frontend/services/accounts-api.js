import Service, { service } from '@ember/service';
import {
  normalizeAccountList,
  normalizeAccountSummary,
} from '../serializers/accounts-api';

const MAX_ACCOUNT_READ_ATTEMPTS = 3;

// Requests can finish out of order: a list showing $100 can arrive after a
// deposit response has already stored $120. Ember Data does not know which
// snapshot is newer, so this service must reject stale reads before store.push.
export default class AccountsApiService extends Service {
  @service store;
  @service userApi;

  // This is a local invalidation counter, not a database revision. It resets
  // when the service is recreated and covers all accounts, so a write to one
  // account can invalidate a read of another. Other tabs/clients do not update
  // it, and it does not order competing reads or competing write responses.
  // Stronger synchronization would need server-generated account revisions,
  // incremented atomically with writes and checked before accepting snapshots.
  // Revisions alone do not discover remote changes; refetching, polling, or
  // server notifications would still be needed for freshness.
  #accountWriteVersion = 0;

  getAccounts() {
    // List payloads are partial; their serializer leaves detail-only fields in
    // Ember Data untouched.
    return this.#readAccountData('/accounts', normalizeAccountList);
  }

  getAccount(accountId) {
    // Detail payloads include the transaction history and account totals.
    return this.#readAccountData(
      '/accounts/' + encodeURIComponent(accountId),
      normalizeAccountSummary,
    );
  }

  noteWrite() {
    // A successful transaction changes account data. Reads started before it
    // will retry instead of restoring an old balance.
    this.#accountWriteVersion += 1;
  }

  async #readAccountData(path, normalize) {
    // Keep the original identity across retries: a stale balance can be
    // refetched, but a request from a previous sign-in must not switch users.
    const identityVersion = this.userApi.identityVersion;
    for (let attempt = 1; attempt <= MAX_ACCOUNT_READ_ATTEMPTS; attempt += 1) {
      const writeVersion = this.#accountWriteVersion;
      const payload = await this.userApi.protectedRequest(
        identityVersion,
        path,
      );
      this.userApi.assertIdentityVersion(identityVersion);
      // Equality means no local transaction response invalidated this read
      // while it was in flight; it does not prove global database freshness.
      if (writeVersion === this.#accountWriteVersion) {
        return this.store.push(normalize(payload));
      }
    }
    // Bound retries so repeated writes cannot leave this read looping forever.
    throw new Error('Account data changed while loading. Try again.');
  }
}
