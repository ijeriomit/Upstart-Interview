import { module, test } from 'qunit';
import { SessionChangedError } from 'accounts-dashboard/services/user-api';
import {
  ACCOUNT,
  accountSummary,
  setupApiServiceTest,
} from 'accounts-dashboard/tests/helpers/api-service-test';

module('Integration | Service | accounts-api', function (hooks) {
  setupApiServiceTest(hooks);

  test('getAccounts pushes partial account records from list endpoint', async function (assert) {
    this.userApi.request = async (path) => {
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
    this.userApi.request = async (path) => {
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

  test('an old account response cannot enter the store after sign-out', async function (assert) {
    let resolveList;
    this.userApi.request = async (path) => {
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
    await this.userApi.signOut();
    resolveList({ accounts: [ACCOUNT] });
    await loading;
    assert.deepEqual(this.pushCalls, []);
  });

  test('getAccounts retries stale reads and pushes only the fresh list payload', async function (assert) {
    let listAttempts = 0;
    let transactionMethod;

    this.userApi.request = async (path, options) => {
      let response;
      if (path === '/accounts') {
        listAttempts += 1;

        if (listAttempts === 1) {
          await this.transactionsApi.createTransaction('1', {
            direction: 'credit',
            amount: '0.20',
            description: '',
          });
        }
        response = {
          accounts:
            listAttempts === 1 ? [ACCOUNT] : [{ ...ACCOUNT, balance: '10.30' }],
        };
      } else if (path === '/accounts/1/transactions') {
        transactionMethod = options.method;
        response = {
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
      } else {
        throw new Error(`Unexpected path: ${path}`);
      }
      return response;
    };

    await this.accountsApi.getAccounts();

    assert.strictEqual(transactionMethod, 'POST');
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

    this.userApi.request = async (path) => {
      if (path === '/accounts') {
        listAttempts += 1;
        await this.transactionsApi.createTransaction('1', {
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
});
