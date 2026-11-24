import { module, test } from 'qunit';
import {
  CREDENTIALS_KEY,
  SessionChangedError,
} from 'accounts-dashboard/services/user-api';
import { setupApiServiceTest } from 'accounts-dashboard/tests/helpers/api-service-test';

module('Integration | Service | user-api', function (hooks) {
  setupApiServiceTest(hooks);

  test('getCurrentUser requests /me and pushes normalized user payload', async function (assert) {
    this.userApi.request = async (path) => {
      assert.strictEqual(path, '/me');
      return {
        user: { id: '1', name: 'Alex Morgan', email: 'alex@example.test' },
      };
    };

    const pushed = await this.userApi.getCurrentUser();

    assert.strictEqual(this.pushCalls.length, 1);
    assert.deepEqual(this.pushCalls[0], {
      data: {
        type: 'user',
        id: '1',
        attributes: {
          name: 'Alex Morgan',
          email: 'alex@example.test',
        },
      },
    });
    assert.strictEqual(pushed, this.pushCalls[0]);
  });

  test('sign-in keeps mock credentials for refresh and sign-out clears them', async function (assert) {
    this.userApi.request = async (path) =>
      path === '/session'
        ? { user: { id: '1', name: 'Alex Morgan', email: 'alex@example.test' } }
        : null;

    await this.userApi.signIn({
      email: 'alex@example.test',
      password: 'mock-password',
    });
    assert.strictEqual(this.userApi.currentUser.data.id, '1');
    assert.deepEqual(JSON.parse(sessionStorage.getItem(CREDENTIALS_KEY)), {
      email: 'alex@example.test',
      password: 'mock-password',
    });
    assert.deepEqual(this.routes, ['accounts.index']);

    await this.userApi.signOut();
    assert.strictEqual(this.userApi.currentUser, null);
    assert.strictEqual(sessionStorage.getItem(CREDENTIALS_KEY), null);
    assert.deepEqual(this.pushCalls, []);
    assert.deepEqual(this.routes, ['accounts.index', 'sign-in']);
  });

  test('register posts the user and opening accounts without storing credentials', async function (assert) {
    const registration = {
      user: {
        name: 'Taylor',
        email: 'taylor@example.test',
        password: 'demo-password',
      },
      accounts: [
        { name: 'Daily', accountType: 'checking', initialDeposit: '0' },
      ],
    };
    this.userApi.request = async (path, options) => {
      assert.strictEqual(path, '/users');
      assert.true(options.public);
      assert.deepEqual(JSON.parse(options.body), registration);
      return {
        user: { id: '3', name: 'Taylor', email: 'taylor@example.test' },
      };
    };

    const saved = await this.userApi.register(registration);
    assert.strictEqual(saved.user.id, '3');
    assert.strictEqual(this.userApi.currentUser, null);
  });

  test('a protected 401 clears the signed-in user and private cache', async function (assert) {
    this.userApi.request = async () => ({
      user: { id: '1', name: 'Alex Morgan', email: 'alex@example.test' },
    });
    await this.userApi.getCurrentUser();
    const identityVersion = this.userApi.identityVersion;
    this.userApi.request = async () => {
      throw Object.assign(new Error('Sign in required.'), { status: 401 });
    };

    await assert.rejects(
      this.userApi.protectedRequest(identityVersion, '/accounts'),
      SessionChangedError,
    );

    assert.strictEqual(this.userApi.currentUser, null);
    assert.strictEqual(sessionStorage.getItem(CREDENTIALS_KEY), null);
    assert.deepEqual(this.pushCalls, []);
    assert.deepEqual(this.routes, ['sign-in']);
  });

  test('request sends Basic credentials only for protected endpoints', async function (assert) {
    const originalFetch = globalThis.fetch;
    const requests = [];
    globalThis.fetch = async (url, options) => {
      requests.push({ url, options });
      return { ok: true, status: 200, json: async () => ({}) };
    };

    try {
      await this.userApi.request('/accounts');
      await this.userApi.request('/session', { public: true });
    } finally {
      globalThis.fetch = originalFetch;
    }

    assert.strictEqual(requests[0].url, '/api/accounts');
    assert.strictEqual(
      requests[0].options.headers.Authorization,
      `Basic ${btoa('alex@example.test:mock-password')}`,
    );
    assert.strictEqual(requests[1].url, '/api/session');
    assert.false('Authorization' in requests[1].options.headers);
  });

  test('request prefixes /api and merges Accept with custom headers', async function (assert) {
    const originalFetch = globalThis.fetch;

    globalThis.fetch = async (url, options) => {
      assert.strictEqual(url, '/api/accounts');
      assert.strictEqual(options.headers.Accept, 'application/json');
      assert.strictEqual(options.headers['Content-Type'], 'application/json');
      return {
        ok: true,
        json: async () => ({ accounts: [] }),
      };
    };

    try {
      await this.userApi.request('/accounts', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
      });
    } finally {
      globalThis.fetch = originalFetch;
    }
  });

  test('request maps network errors to connectivity guidance', async function (assert) {
    const originalFetch = globalThis.fetch;
    globalThis.fetch = async () => {
      throw new Error('offline');
    };

    try {
      await assert.rejects(
        this.userApi.request('/accounts'),
        /Could not reach the API\. Check that Rails is running\./,
      );
    } finally {
      globalThis.fetch = originalFetch;
    }
  });

  test('request maps API error payloads and malformed JSON failures', async function (assert) {
    const originalFetch = globalThis.fetch;

    globalThis.fetch = async () => ({
      ok: false,
      json: async () => ({ error: { message: 'Custom backend error.' } }),
    });

    try {
      await assert.rejects(
        this.userApi.request('/accounts'),
        /Custom backend error\./,
      );
    } finally {
      globalThis.fetch = originalFetch;
    }

    globalThis.fetch = async () => ({
      ok: true,
      json: async () => {
        throw new Error('bad json');
      },
    });

    try {
      await assert.rejects(
        this.userApi.request('/accounts'),
        /The API request failed\./,
      );
    } finally {
      globalThis.fetch = originalFetch;
    }
  });
});
