import { module, test } from 'qunit';
import { SessionChangedError } from 'accounts-dashboard/services/user-api';
import {
  ACCOUNT,
  accountSummary,
  setupApiServiceTest,
} from 'accounts-dashboard/tests/helpers/api-service-test';

module('Integration | Service | transactions-api', function (hooks) {
  setupApiServiceTest(hooks);

  test('createTransaction POSTs JSON payload and pushes updated summary', async function (assert) {
    let sentPath;
    let sentOptions;
    this.userApi.request = async (path, options) => {
      sentPath = path;
      sentOptions = options;
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
    };

    const pushed = await this.transactionsApi.createTransaction('1', {
      direction: 'credit',
      amount: '0.20',
      description: 'Practice deposit',
    });

    assert.strictEqual(sentPath, '/accounts/1/transactions');
    assert.strictEqual(sentOptions.method, 'POST');
    assert.strictEqual(sentOptions.headers['Content-Type'], 'application/json');
    assert.deepEqual(JSON.parse(sentOptions.body), {
      transaction: {
        direction: 'credit',
        amount: '0.20',
        description: 'Practice deposit',
      },
    });
    assert.strictEqual(this.pushCalls.length, 1);
    assert.strictEqual(this.pushCalls[0].data.attributes.balance, '10.30');
    assert.strictEqual(this.pushCalls[0].included[0].attributes.amount, '0.20');
    assert.strictEqual(pushed, this.pushCalls[0]);
  });

  test('a transaction reply from before sign-out cannot repopulate the store', async function (assert) {
    let resolveTransaction;
    this.userApi.request = async () =>
      new Promise((resolve) => {
        resolveTransaction = resolve;
      });

    const posting = assert.rejects(
      this.transactionsApi.createTransaction('1', {
        direction: 'credit',
        amount: '0.20',
        description: '',
      }),
      SessionChangedError,
    );
    await this.userApi.signOut();
    resolveTransaction(accountSummary());
    await posting;

    assert.deepEqual(this.pushCalls, []);
  });
});
