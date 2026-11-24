import Service from '@ember/service';
import { module, test } from 'qunit';
import {
  CREDENTIALS_KEY,
  SessionChangedError,
} from 'accounts-dashboard/services/accounts-api';
import { setupTest } from 'accounts-dashboard/tests/helpers';

const ACCOUNT = { id: '1', name: 'Everyday checking', balance: '10.10' };

function accountSummary(currentAccount = ACCOUNT) {
  return {
    account: currentAccount,
    totalCredits: '0.00',
    totalDebits: '0.00',
    transactions: [],
  };
}

module('Integration | Service | accounts-api', function (hooks) {
  setupTest(hooks);

  hooks.beforeEach(function () {
    sessionStorage.setItem(
      CREDENTIALS_KEY,
      JSON.stringify({ email: 'alex@example.test', password: 'mock-password' }),
    );
    this.pushCalls = [];
    this.routes = [];
    const pushCalls = this.pushCalls;
    const routes = this.routes;

    this.owner.register(
      'service:store',
      class extends Service {
        unloadAll() {
          pushCalls.length = 0;
        }

        push(payload) {
          pushCalls.push(payload);
          return payload;
        }
      },
    );
    this.owner.register(
      'service:router',
      class extends Service {
        replaceWith(route) {
          routes.push(route);
        }
      },
    );

    this.accountsApi = this.owner.lookup('service:accounts-api');
  });

  hooks.afterEach(function () {
    sessionStorage.removeItem(CREDENTIALS_KEY);
  });

  test('getCurrentUser requests /me and pushes normalized user payload', async function (assert) {
    this.accountsApi.request = async (path) => {
      assert.strictEqual(path, '/me');
      return {
        user: { id: '1', name: 'Alex Morgan', email: 'alex@example.test' },
      };
    };

    const pushed = await this.accountsApi.getCurrentUser();

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

  test('getAccounts pushes partial account records from list endpoint', async function (assert) {
    this.accountsApi.request = async (path) => {
      assert.strictEqual(path, '/accounts');
      return {
        accounts: [
          {
            id: '1',
            name: 'Everyday checking',
            balance: '10.10',
            totalCredits: '99.99',
          },
        ],
      };
    };

    await this.accountsApi.getAccounts();

    assert.deepEqual(this.pushCalls[0], {
      data: [
        {
          type: 'account',
          id: '1',
          attributes: {
            name: 'Everyday checking',
            balance: '10.10',
          },
        },
      ],
    });
  });

  test('getAccount pushes summary with transactions relationship', async function (assert) {
    this.accountsApi.request = async (path) => {
      assert.strictEqual(path, '/accounts/1');
      return {
        account: ACCOUNT,
        totalCredits: '1.50',
        totalDebits: '0.00',
        transactions: [
          {
            id: '2',
            accountId: '1',
            direction: 'credit',
            amount: '1.50',
            description: 'Practice deposit',
            createdAt: '2026-01-02T12:00:00Z',
          },
        ],
      };
    };

    await this.accountsApi.getAccount('1');

    assert.deepEqual(this.pushCalls[0].data.relationships.transactions.data, [
      { type: 'transaction', id: '2' },
    ]);
    assert.strictEqual(this.pushCalls[0].included[0].id, '2');
    assert.strictEqual(
      this.pushCalls[0].data.attributes.totalCredits,
      '1.50',
      'keeps decimal strings from Rails',
    );
  });

  test('sign-in keeps mock credentials for refresh and sign-out clears them', async function (assert) {
    this.accountsApi.request = async (path) =>
      path === '/session'
        ? { user: { id: '1', name: 'Alex Morgan', email: 'alex@example.test' } }
        : null;

    await this.accountsApi.signIn({
      email: 'alex@example.test',
      password: 'mock-password',
    });
    assert.strictEqual(this.accountsApi.currentUser.data.id, '1');
    assert.deepEqual(JSON.parse(sessionStorage.getItem(CREDENTIALS_KEY)), {
      email: 'alex@example.test',
      password: 'mock-password',
    });
    assert.deepEqual(this.routes, ['accounts.index']);

    await this.accountsApi.signOut();
    assert.strictEqual(this.accountsApi.currentUser, null);
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
    this.accountsApi.request = async (path, options) => {
      assert.strictEqual(path, '/users');
      assert.strictEqual(options.public, true);
      assert.deepEqual(JSON.parse(options.body), registration);
      return {
        user: { id: '3', name: 'Taylor', email: 'taylor@example.test' },
      };
    };

    const saved = await this.accountsApi.register(registration);
    assert.strictEqual(saved.user.id, '3');
    assert.strictEqual(this.accountsApi.currentUser, null);
  });

  test('an old account response cannot enter the store after sign-out', async function (assert) {
    let resolveList;
    this.accountsApi.request = async (path) => {
      if (path === '/accounts') {
        return new Promise((resolve) => {
          resolveList = resolve;
        });
      }
      return null;
    };

    const loading = assert.rejects(
      this.accountsApi.getAccounts(),
      SessionChangedError,
    );
    await this.accountsApi.signOut();
    resolveList({ accounts: [ACCOUNT] });
    await loading;
    assert.deepEqual(this.pushCalls, []);
  });

  test('createTransaction POSTs JSON payload and pushes updated summary', async function (assert) {
    assert.expect(7);

    this.accountsApi.request = async (path, options) => {
      if (path === '/accounts/1/transactions') {
        assert.strictEqual(options.method, 'POST');
        assert.strictEqual(options.headers['Content-Type'], 'application/json');
        assert.deepEqual(JSON.parse(options.body), {
          transaction: {
            direction: 'credit',
            amount: '0.20',
            description: 'Practice deposit',
          },
        });

        return {
          ...accountSummary({ ...ACCOUNT, balance: '10.30' }),
          totalCredits: '0.20',
          transactions: [
            {
              id: '2',
              accountId: '1',
              direction: 'credit',
              amount: '0.20',
              description: 'Practice deposit',
              createdAt: '2026-01-02T12:00:00Z',
            },
          ],
        };
      }

      throw new Error(`Unexpected path: ${path}`);
    };

    const pushed = await this.accountsApi.createTransaction('1', {
      direction: 'credit',
      amount: '0.20',
      description: 'Practice deposit',
    });

    assert.strictEqual(this.pushCalls.length, 1);
    assert.strictEqual(this.pushCalls[0].data.attributes.balance, '10.30');
    assert.strictEqual(this.pushCalls[0].included[0].attributes.amount, '0.20');
    assert.strictEqual(pushed, this.pushCalls[0]);
  });

  test('getAccounts retries stale reads and pushes only the fresh list payload', async function (assert) {
    let listAttempts = 0;

    this.accountsApi.request = async (path, options) => {
      if (path === '/accounts') {
        listAttempts += 1;

        if (listAttempts === 1) {
          await this.accountsApi.createTransaction('1', {
            direction: 'credit',
            amount: '0.20',
            description: '',
          });
          return { accounts: [ACCOUNT] };
        }

        return {
          accounts: [{ ...ACCOUNT, balance: '10.30' }],
        };
      }

      if (path === '/accounts/1/transactions') {
        assert.strictEqual(options.method, 'POST');
        return {
          ...accountSummary({ ...ACCOUNT, balance: '10.30' }),
          totalCredits: '0.20',
          transactions: [
            {
              id: '2',
              accountId: '1',
              direction: 'credit',
              amount: '0.20',
              description: '',
              createdAt: '2026-01-02T12:00:00Z',
            },
          ],
        };
      }

      throw new Error(`Unexpected path: ${path}`);
    };

    await this.accountsApi.getAccounts();

    assert.strictEqual(listAttempts, 2);
    assert.strictEqual(
      this.pushCalls.length,
      2,
      'transaction summary + fresh list',
    );

    const listPush = this.pushCalls[1];
    assert.deepEqual(listPush, {
      data: [
        {
          type: 'account',
          id: '1',
          attributes: {
            name: 'Everyday checking',
            balance: '10.30',
          },
        },
      ],
    });
  });

  test('getAccounts throws after three stale reads', async function (assert) {
    let listAttempts = 0;

    this.accountsApi.request = async (path) => {
      if (path === '/accounts') {
        listAttempts += 1;
        await this.accountsApi.createTransaction('1', {
          direction: 'credit',
          amount: '0.20',
          description: '',
        });
        return { accounts: [ACCOUNT] };
      }

      if (path === '/accounts/1/transactions') {
        return {
          ...accountSummary({ ...ACCOUNT, balance: '10.30' }),
          totalCredits: '0.20',
          transactions: [
            {
              id: String(listAttempts + 1),
              accountId: '1',
              direction: 'credit',
              amount: '0.20',
              description: '',
              createdAt: '2026-01-02T12:00:00Z',
            },
          ],
        };
      }

      throw new Error(`Unexpected path: ${path}`);
    };

    await assert.rejects(
      this.accountsApi.getAccounts(),
      /Account data changed while loading\. Try again\./,
    );
    assert.strictEqual(listAttempts, 3);
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
      await this.accountsApi.request('/accounts', {
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
        this.accountsApi.request('/accounts'),
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
        this.accountsApi.request('/accounts'),
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
        this.accountsApi.request('/accounts'),
        /The API request failed\./,
      );
    } finally {
      globalThis.fetch = originalFetch;
    }
  });
});
