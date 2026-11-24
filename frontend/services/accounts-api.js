import Service, { service } from '@ember/service';
import { waitFor } from '@ember/test-waiters';
import { tracked } from '@glimmer/tracking';
import {
  normalizeAccountList,
  normalizeAccountSummary,
  normalizeCurrentUser,
} from '../serializers/accounts-api';

const MAX_ACCOUNT_READ_ATTEMPTS = 3;
export const CREDENTIALS_KEY = 'accounts-dashboard:credentials';

// Preserve the HTTP status so a signed-out response can be distinguished from
// a network or validation error.
class ApiError extends Error {
  constructor(message, status) {
    super(message);
    this.status = status;
  }
}

export class SessionChangedError extends Error {
  constructor() {
    super('Your signed-in user changed. Please try again.');
  }
}

// This interview service owns API transport and the current user. Credentials
// live in this tab's sessionStorage so a refresh can restore the user; Rails
// checks them again on every protected request.
export default class AccountsApiService extends Service {
  @service router;
  @service store;
  @tracked currentUser = null;
  @tracked isChangingSession = false;

  #credentials = null;
  #generation = 0;
  #writeRevision = 0;

  constructor() {
    super(...arguments);
    this.#credentials = this.#savedCredentials();
  }

  async getCurrentUser() {
    // ApplicationRoute calls this on boot. A missing or rejected credential
    // opens the public sign-in route; an API outage still reaches the error UI.
    if (!this.#credentials) return null;
    const generation = this.#generation;
    try {
      const payload = await this.request('/me');
      this.#checkGeneration(generation);
      this.currentUser = this.store.push(normalizeCurrentUser(payload));
      return this.currentUser;
    } catch (error) {
      this.#checkGeneration(generation);
      if (error.status !== 401) throw error;
      this.#clearIdentity();
      return null;
    }
  }

  async signIn(credentials) {
    if (this.isChangingSession) return;
    this.isChangingSession = true;
    try {
      const payload = await this.request('/session', {
        method: 'POST',
        public: true,
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ session: credentials }),
      });
      sessionStorage.setItem(CREDENTIALS_KEY, JSON.stringify(credentials));
      this.#credentials = credentials;
      this.#setIdentity(payload);
      await this.router.replaceWith('accounts.index');
    } finally {
      this.isChangingSession = false;
    }
  }

  async signOut() {
    // No server session exists. Removing this tab's saved credential is the
    // complete mock sign-out operation.
    this.#clearIdentity();
    await this.router.replaceWith('sign-in');
  }

  register({ user, accounts }) {
    // Registration is public and Rails commits the user and opening accounts
    // together. The new user signs in after this request succeeds.
    return this.request('/users', {
      method: 'POST',
      public: true,
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ user, accounts }),
    });
  }

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

  async createTransaction(accountId, transaction) {
    const generation = this.#generation;
    const summary = await this.#accountRequest(
      generation,
      '/accounts/' + encodeURIComponent(accountId) + '/transactions',
      {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ transaction }),
      },
    );
    this.#checkGeneration(generation);
    this.#writeRevision += 1;
    return this.store.push(normalizeAccountSummary(summary));
  }

  async #readAccountData(path, normalize) {
    // A write can finish while a read is in flight. Retry rather than
    // overwriting a newer balance, and reject replies from a prior user.
    const generation = this.#generation;
    for (let attempt = 1; attempt <= MAX_ACCOUNT_READ_ATTEMPTS; attempt += 1) {
      const revision = this.#writeRevision;
      const payload = await this.#accountRequest(generation, path);
      this.#checkGeneration(generation);
      if (revision === this.#writeRevision) {
        return this.store.push(normalize(payload));
      }
    }
    throw new Error('Account data changed while loading. Try again.');
  }

  #setIdentity(payload) {
    // Invalidate old replies before replacing private Ember Data records.
    this.#generation += 1;
    this.store.unloadAll();
    this.currentUser = this.store.push(normalizeCurrentUser(payload));
  }

  #clearIdentity() {
    this.#generation += 1;
    this.#credentials = null;
    sessionStorage.removeItem(CREDENTIALS_KEY);
    this.store.unloadAll();
    this.currentUser = null;
  }

  #savedCredentials() {
    try {
      const value = JSON.parse(sessionStorage.getItem(CREDENTIALS_KEY));
      return typeof value?.email === 'string' &&
        typeof value?.password === 'string'
        ? value
        : null;
    } catch {
      return null;
    }
  }

  #checkGeneration(generation) {
    if (generation !== this.#generation) throw new SessionChangedError();
  }

  async #accountRequest(generation, path, options) {
    try {
      return await this.request(path, options);
    } catch (error) {
      this.#checkGeneration(generation);
      if (error.status === 401) {
        this.#clearIdentity();
        void this.router.replaceWith('sign-in');
        throw new SessionChangedError();
      }
      throw error;
    } finally {
      this.#checkGeneration(generation);
    }
  }

  // The only raw fetch boundary. The browser sends mock Basic credentials for
  // protected requests; sign-in and registration explicitly opt out.
  @waitFor
  async request(path, options = {}) {
    const { public: isPublic, ...fetchOptions } = options;
    const credentials = isPublic ? null : this.#credentials;
    const authorization = credentials
      ? { Authorization: this.#basicAuthorization(credentials) }
      : {};
    let response;
    try {
      // eslint-disable-next-line warp-drive/no-external-request-patterns -- This service owns the interview API's plain JSON transport.
      response = await fetch('/api' + path, {
        ...fetchOptions,
        headers: {
          Accept: 'application/json',
          ...authorization,
          ...options.headers,
        },
      });
    } catch {
      throw new Error('Could not reach the API. Check that Rails is running.');
    }
    if (response.status === 204) return null;
    const payload = await response.json().catch(() => null);
    if (!response.ok || payload === null) {
      throw new ApiError(
        payload?.error?.message ?? 'The API request failed.',
        response.status,
      );
    }
    return payload;
  }

  #basicAuthorization({ email, password }) {
    // Base64 is HTTP Basic formatting, not encryption. Encode UTF-8 so the
    // same mock password works with non-ASCII characters.
    const bytes = new TextEncoder().encode(`${email}:${password}`);
    return `Basic ${btoa(String.fromCharCode(...bytes))}`;
  }
}
