import Service, { service } from '@ember/service';
import { waitFor } from '@ember/test-waiters';
import {
  normalizeAccountList,
  normalizeAccountSummary,
  normalizeCurrentUser,
} from '../serializers/accounts-api';

const MAX_ACCOUNT_READ_ATTEMPTS = 3;

export default class AccountsApiService extends Service {
  @service store;
  #writeRevision = 0;

  async getCurrentUser() {
    const payload = await this.request('/me');
    return this.store.push(normalizeCurrentUser(payload));
  }

  getAccounts() {
    return this.#readAccountData('/accounts', normalizeAccountList);
  }

  getAccount(accountId) {
    return this.#readAccountData(
      '/accounts/' + encodeURIComponent(accountId),
      normalizeAccountSummary,
    );
  }

  async createTransaction(accountId, transaction) {
    const summary = await this.request(
      '/accounts/' + encodeURIComponent(accountId) + '/transactions',
      {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ transaction }),
      },
    );
    this.#writeRevision += 1;
    return this.store.push(normalizeAccountSummary(summary));
  }

  async #readAccountData(path, normalize) {
    for (let attempt = 1; attempt <= MAX_ACCOUNT_READ_ATTEMPTS; attempt += 1) {
      const revisionAtStart = this.#writeRevision;
      const payload = await this.request(path);

      // A transaction posted during this read may have updated the store.
      if (revisionAtStart === this.#writeRevision) {
        return this.store.push(normalize(payload));
      }
    }

    throw new Error('Account data changed while loading. Try again.');
  }

  // The injected service centralizes HTTP behavior. A test waiter lets Ember
  // know when fetch calls started by a UI action have finished.
  @waitFor
  async request(path, options) {
    let response;
    try {
      // eslint-disable-next-line warp-drive/no-external-request-patterns -- This service owns the interview API's plain JSON transport.
      response = await fetch('/api' + path, {
        ...options,
        headers: { Accept: 'application/json', ...options?.headers },
      });
    } catch {
      throw new Error('Could not reach the API. Check that Rails is running.');
    }

    const payload = await response.json().catch(() => null);
    if (!response.ok || payload === null) {
      throw new Error(payload?.error?.message ?? 'The API request failed.');
    }
    return payload;
  }
}
