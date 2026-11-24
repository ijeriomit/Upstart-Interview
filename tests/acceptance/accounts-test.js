import { click, currentURL, fillIn, visit } from '@ember/test-helpers';
import { module, test } from 'qunit';
import AccountModel from 'accounts-dashboard/models/account';
import TransactionModel from 'accounts-dashboard/models/transaction';
import UserModel from 'accounts-dashboard/models/user';
import { setupAccountsApiStub } from 'accounts-dashboard/tests/helpers/accounts-api-stub';
import {
  ACCOUNT_FIXTURE,
  USER_FIXTURE,
} from 'accounts-dashboard/tests/helpers/accounts-fixtures';
import { setupApplicationTest } from 'accounts-dashboard/tests/helpers';

module('Acceptance | Accounts Dashboard', function (hooks) {
  setupApplicationTest(hooks);

  hooks.beforeEach(function () {
    setupAccountsApiStub(this);
  });

  test('navigates from the account list and applies the updated summary', async function (assert) {
    await visit('/');
    assert.strictEqual(currentURL(), '/accounts');
    assert.dom('main h1').hasText('Accounts');

    const userRecord = this.owner.lookup('controller:accounts').model;
    const [accountRecord] = this.owner.lookup(
      'controller:accounts/index',
    ).model;
    assert.true(userRecord instanceof UserModel);
    assert.strictEqual(userRecord.email, USER_FIXTURE.email);
    assert.true(accountRecord instanceof AccountModel);

    await click('main a[href="/accounts/1"]');
    assert.strictEqual(currentURL(), '/accounts/1');
    assert.dom('main').includesText('No transactions yet.');
    assert.dom('[data-test-balance]').hasText('$10.10');
    assert.strictEqual(
      this.owner.lookup('controller:accounts/show').model,
      accountRecord,
    );

    await fillIn('input[name="amount"]', '0.20');
    await fillIn('input[name="description"]', 'Practice deposit');
    await click('button[type="submit"]');

    assert.deepEqual(this.submissions, [
      {
        path: '/accounts/1/transactions',
        method: 'POST',
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

    const [transaction] = accountRecord.transactions;
    assert.strictEqual(accountRecord.totalCredits, '0.20');
    assert.true(transaction instanceof TransactionModel);
    assert.strictEqual(transaction.id, '2');
    assert.strictEqual(transaction.account, accountRecord);
  });

  test('keeps a posted balance when an older list response arrives afterward', async function (assert) {
    await visit('/accounts/1');
    const accountsApi = this.owner.lookup('service:accounts-api');
    const accountRecord = this.owner.lookup('controller:accounts/show').model;

    let resolveOldList;
    this.accountLists.push(
      new Promise((resolve) => {
        resolveOldList = resolve;
      }),
      { accounts: [{ ...ACCOUNT_FIXTURE, balance: '10.30' }] },
    );
    const loadingAccounts = accountsApi.getAccounts();
    await this.owner.lookup('service:transactions-api').createTransaction('1', {
      direction: 'credit',
      amount: '0.20',
      description: '',
    });
    resolveOldList({ accounts: [ACCOUNT_FIXTURE] });

    const [listedAccount] = await loadingAccounts;
    assert.strictEqual(listedAccount, accountRecord);
    assert.strictEqual(listedAccount.balance, '10.30');
    assert.strictEqual(listedAccount.totalCredits, '0.20');
    assert.strictEqual(listedAccount.transactions.length, 1);
  });

  test('stops after three stale account reads and keeps the posted summary', async function (assert) {
    await visit('/accounts/1');
    const accountsApi = this.owner.lookup('service:accounts-api');
    const accountRecord = this.owner.lookup('controller:accounts/show').model;
    const userApi = this.owner.lookup('service:user-api');
    const request = userApi.request.bind(userApi);
    let listAttempts = 0;

    userApi.request = async (path, options) => {
      if (path === '/accounts') {
        listAttempts += 1;
        if (listAttempts <= 3) {
          await this.owner.lookup('service:transactions-api').createTransaction('1', {
            direction: 'credit',
            amount: '0.20',
            description: '',
          });
        }
      }
      return request(path, options);
    };

    await assert.rejects(
      accountsApi.getAccounts(),
      /Account data changed while loading\. Try again\./,
    );
    assert.strictEqual(listAttempts, 3);
    assert.strictEqual(accountRecord.balance, '10.30');
    assert.strictEqual(accountRecord.totalCredits, '0.20');
    assert.strictEqual(accountRecord.transactions.length, 1);
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
