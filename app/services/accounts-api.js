import Service from '@ember/service';
import { waitFor } from '@ember/test-waiters';

export default class AccountsApiService extends Service {
  async getCurrentUser() {
    return (await this.request('/me')).user;
  }

  async getAccounts() {
    return (await this.request('/accounts')).accounts;
  }

  getAccount(accountId) {
    return this.request('/accounts/' + encodeURIComponent(accountId));
  }

  createTransaction(accountId, transaction) {
    return this.request(
      '/accounts/' + encodeURIComponent(accountId) + '/transactions',
      {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ transaction }),
      },
    );
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
