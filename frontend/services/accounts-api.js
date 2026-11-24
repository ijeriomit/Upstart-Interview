import Service, { service } from '@ember/service';
import {
  normalizeAccountList,
  normalizeAccountSummary,
} from '../serializers/accounts-api';

const MAX_ACCOUNT_READ_ATTEMPTS = 3;

// A list fetched before a transaction must not replace the newer balance
// returned by that transaction.
export default class AccountsApiService extends Service {
  @service store;
  @service userApi;

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
    const identityVersion = this.userApi.identityVersion;
    for (let attempt = 1; attempt <= MAX_ACCOUNT_READ_ATTEMPTS; attempt += 1) {
      const writeVersion = this.#accountWriteVersion;
      const payload = await this.userApi.protectedRequest(
        identityVersion,
        path,
      );
      this.userApi.assertIdentityVersion(identityVersion);
      if (writeVersion === this.#accountWriteVersion) {
        return this.store.push(normalize(payload));
      }
    }
    throw new Error('Account data changed while loading. Try again.');
  }
}
