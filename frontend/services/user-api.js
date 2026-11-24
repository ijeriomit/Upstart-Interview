import Service, { service } from '@ember/service';
import { waitFor } from '@ember/test-waiters';
import { tracked } from '@glimmer/tracking';
import { normalizeCurrentUser } from '../serializers/accounts-api';

export const CREDENTIALS_KEY = 'accounts-dashboard:credentials';

// Keep the HTTP status so a 401 can be handled differently from a network or
// validation error.
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

// This interview service owns identity and API transport. Credentials live in
// this tab's sessionStorage so a refresh can restore the user. Rails checks
// them again on every protected request.
//
// Security boundary: browser state and version checks prevent stale UI updates,
// not unauthorized API access. Rails must authenticate each protected request
// and Pundit must enforce account ownership even if this client is bypassed.
// sessionStorage holds a reusable plaintext password readable by same-origin
// JavaScript; its tab-scoped lifetime does not protect it from XSS.
//
// Production direction (not implemented): use established password hashing on
// the server, HTTPS, and a server-managed session with HttpOnly/Secure cookies
// and an appropriate SameSite policy. Cookie-authenticated writes also need
// CSRF protection. Rotate session IDs on login, support expiry/revocation, and
// rate-limit login attempts. HttpOnly prevents script from reading the cookie,
// but XSS can still issue authenticated requests, so safe rendering remains
// necessary. These changes require a coordinated frontend/backend contract.
export default class UserApiService extends Service {
  @service router;
  @service store;
  @tracked currentUser = null;
  @tracked isChangingSession = false;

  #credentials = null;
  #identityVersion = 0;

  constructor() {
    super(...arguments);
    this.#credentials = this.#savedCredentials();
  }

  get identityVersion() {
    // Capture this number when work starts. If it changes before the reply,
    // sign-in or sign-out happened and the reply belongs to the previous user.
    // Clearing the store alone is insufficient: Alex's delayed response could
    // otherwise repopulate it after Jordan signs in. This generation is local
    // browser state, not a server token or cross-tab session synchronization.
    return this.#identityVersion;
  }

  assertIdentityVersion(identityVersion) {
    if (identityVersion !== this.#identityVersion) {
      throw new SessionChangedError();
    }
  }

  async getCurrentUser() {
    // ApplicationRoute calls this on boot. A missing or rejected credential
    // opens the public sign-in route; an API outage still reaches the error UI.
    if (!this.#credentials) return null;
    const identityVersion = this.#identityVersion;
    try {
      const payload = await this.request('/me');
      this.assertIdentityVersion(identityVersion);
      this.currentUser = this.store.push(normalizeCurrentUser(payload));
      return this.currentUser;
    } catch (error) {
      this.assertIdentityVersion(identityVersion);
      if (error.status !== 401) throw error;
      this.#clearIdentity();
      return null;
    }
  }

  async signIn(credentials) {
    // Prevent overlapping calls to this method, not unauthorized requests.
    // Known lifecycle gap: sign-in does not capture/check an identity version.
    // If signOut runs while this request is pending, its successful reply can
    // establish identity again. Production session handling should invalidate
    // pending login attempts as well as protected reads/writes.
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
    // This mock flow has no server session. Remove the saved credentials and
    // private records from this tab, then show the public sign-in route.
    // This does not revoke the password or undo requests Rails already handled.
    // A transaction may commit even though its late response is rejected here.
    // Cancelling fetch could reduce wasted work but cannot guarantee rollback;
    // server session revocation and database write semantics are separate.
    this.#clearIdentity();
    await this.router.replaceWith('sign-in');
  }

  register({ user, accounts }) {
    // Rails creates the user and opening accounts together. Registration is
    // public and leaves the new user signed out until they use the sign-in form.
    return this.request('/users', {
      method: 'POST',
      public: true,
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ user, accounts }),
    });
  }

  #setIdentity(payload) {
    // Invalidate replies started by the previous user. Clear all Ember Data
    // records from browser memory before storing the new user. This does not
    // delete any Rails data.
    this.#identityVersion += 1;
    this.store.unloadAll();
    this.currentUser = this.store.push(normalizeCurrentUser(payload));
  }

  #clearIdentity() {
    // Invalidate old replies and remove only this app's credentials key from
    // sessionStorage. Clear cached Ember Data records and UI identity.
    this.#identityVersion += 1;
    this.#credentials = null;
    sessionStorage.removeItem(CREDENTIALS_KEY);
    this.store.unloadAll();
    this.currentUser = null;
  }

  #savedCredentials() {
    // Read this tab's saved mock credentials during service construction.
    // Missing or malformed data means the browser starts signed out.
    // Checking string types validates storage shape only. GET /me must still
    // ask Rails whether the credentials are valid before restoring identity.
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

  async protectedRequest(identityVersion, path, options) {
    // Account and transaction services use this wrapper. A 401 clears the
    // identity; a reply from a prior user cannot reach Ember Data.
    // Check identity on failures BEFORE handling 401: Alex's delayed rejection
    // must not clear Jordan's newer sign-in. Other errors propagate without
    // clearing credentials; an outage or validation error is not failed auth.
    try {
      const payload = await this.request(path, options);
      this.assertIdentityVersion(identityVersion);
      return payload;
    } catch (error) {
      this.assertIdentityVersion(identityVersion);
      if (error.status === 401) {
        this.#clearIdentity();
        void this.router.replaceWith('sign-in');
        throw new SessionChangedError();
      }
      throw error;
    }
  }

  // The only raw fetch boundary. Protected requests send mock Basic
  // credentials; sign-in and registration explicitly opt out.
  // `public` only suppresses this client's Authorization header; Rails decides
  // which endpoints allow unauthenticated access. This raw method does not
  // enforce identity generations; protectedRequest and boot restoration do.
  // @waitFor lets Ember tests track this asynchronous work; it is not security.
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
    // HTTPS is required to protect credentials in transit; encoding provides
    // neither transport protection nor safe password storage.
    const bytes = new TextEncoder().encode(`${email}:${password}`);
    return `Basic ${btoa(String.fromCharCode(...bytes))}`;
  }
}
