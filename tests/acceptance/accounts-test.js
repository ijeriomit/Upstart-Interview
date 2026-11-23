import { click, currentURL, fillIn, visit } from '@ember/test-helpers';
import Service from '@ember/service';
import { module, test } from 'qunit';
import { setupApplicationTest } from 'battery-dashboard/tests/helpers';

const account = { id: '1', name: 'Everyday checking', balance: '10.10' };

function accountSummary(currentAccount = account) {
  return {
    account: currentAccount,
    totalCredits: '0.00',
    totalDebits: '0.00',
    transactions: [],
  };
}

module('Acceptance | Fieldwork accounts', function (hooks) {
  setupApplicationTest(hooks);

  hooks.beforeEach(function () {
    this.submissions = [];
    const submissions = this.submissions;
    this.owner.register(
      'service:accounts-api',
      class extends Service {
        async getCurrentUser() {
          return { name: 'Alex Morgan' };
        }

        async getAccounts() {
          return [account];
        }

        async getAccount() {
          return accountSummary();
        }

        async createTransaction(accountId, transaction) {
          submissions.push({ accountId, transaction });
          if (transaction.amount === '0.201') {
            throw new Error('Enter a decimal amount with two decimal places.');
          }
          return {
            ...accountSummary({ ...account, balance: '10.30' }),
            totalCredits: '0.20',
            transactions: [
              { ...transaction, id: '2', createdAt: '2026-01-02T12:00:00Z' },
            ],
          };
        }
      },
    );
  });

  test('navigates from the account list and applies the updated summary', async function (assert) {
    await visit('/');
    assert.strictEqual(currentURL(), '/accounts');
    assert.dom('main h1').hasText('Accounts');

    await click('main a[href="/accounts/1"]');
    assert.strictEqual(currentURL(), '/accounts/1');
    assert.dom('main').includesText('No transactions yet.');
    assert.dom('[data-test-balance]').hasText('$10.10');

    await fillIn('input[name="amount"]', '0.20');
    await fillIn('input[name="description"]', 'Practice deposit');
    await click('button[type="submit"]');

    assert.deepEqual(this.submissions, [
      {
        accountId: '1',
        transaction: {
          direction: 'credit',
          amount: '0.20',
          description: 'Practice deposit',
        },
      },
    ]);
    assert.dom('[data-test-balance]').hasText('$10.30');
    assert.dom('[data-test-transaction]').includesText('Practice deposit');
    assert.dom('[role="status"]').hasText('Transaction recorded.');
    assert.dom('input[name="amount"]').hasValue('');
  });

  test('keeps the form values and old balance when the API rejects a transaction', async function (assert) {
    await visit('/accounts/1');
    await fillIn('input[name="amount"]', '0.201');
    await click('button[type="submit"]');

    assert
      .dom('[role="alert"]')
      .hasText('Enter a decimal amount with two decimal places.');
    assert.dom('input[name="amount"]').hasValue('0.201');
    assert.dom('[data-test-balance]').hasText('$10.10');
  });
});
