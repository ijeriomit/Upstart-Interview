import { find, render } from '@ember/test-helpers';
import { module, test } from 'qunit';
import SignUpForm from 'accounts-dashboard/components/sign-up-form';
import { setupRenderingTest } from 'accounts-dashboard/tests/helpers';
import {
  addAccount,
  accountRow,
  fillAccount,
  fillUser,
  removeAccount,
  submitSignUp,
} from 'accounts-dashboard/tests/helpers/demo-sign-up-form';

module('Integration | Component | sign-up-form', function (hooks) {
  setupRenderingTest(hooks);

  hooks.beforeEach(async function () {
    this.submissions = [];
    const onSubmit = (data) => this.submissions.push(data);
    await render(<template><SignUpForm @onSubmit={{onSubmit}} /></template>);
  });

  test('submits user and account fields, including a zero deposit', async function (assert) {
    await fillUser();
    await fillAccount(1, { name: 'Checking', type: 'checking', deposit: '0' });
    await submitSignUp();

    assert.deepEqual(this.submissions, [
      {
        user: {
          name: 'Taylor Morgan',
          email: 'taylor@example.test',
          password: 'demo-password',
        },
        accounts: [
          { name: 'Checking', accountType: 'checking', initialDeposit: '0' },
        ],
      },
    ]);
  });

  for (const deposit of ['-1', 'abc', '1.001']) {
    test(`rejects deposit ${deposit}`, async function (assert) {
      await fillUser();
      await fillAccount(1, { name: 'Checking', type: 'checking', deposit });
      await submitSignUp();

      assert.true(
        find('input[name="initialDeposit"]').validity.patternMismatch,
      );
      assert
        .dom('input[name="initialDeposit"]')
        .hasAttribute('aria-invalid', 'true');
      assert.dom('[role="status"]').includesText('Enter a nonnegative amount');
      assert.deepEqual(this.submissions, []);
    });
  }

  test('clears the deposit error when corrected', async function (assert) {
    await fillAccount(1, { deposit: '-1' });
    await fillAccount(1, { deposit: '1.25' });

    assert.false(find('input[name="initialDeposit"]').validity.patternMismatch);
    assert.dom('[role="status"]').doesNotExist();
  });

  for (const { field, account } of [
    {
      field: 'input[name="accountName"]',
      account: { type: 'checking', deposit: '0' },
    },
    {
      field: 'select[name="accountType"]',
      account: { name: 'Checking', deposit: '0' },
    },
    {
      field: 'input[name="initialDeposit"]',
      account: { name: 'Checking', type: 'checking' },
    },
  ]) {
    test(`requires ${field} for an opening account`, async function (assert) {
      await fillUser();
      await fillAccount(1, account);
      await submitSignUp();

      assert.true(find(field).validity.valueMissing);
      assert.deepEqual(this.submissions, []);
    });
  }

  test('rejects an account name made only of spaces', async function (assert) {
    await fillUser();
    await fillAccount(1, { name: '   ', type: 'checking', deposit: '0' });
    await submitSignUp();

    assert.dom('[role="alert"]').includesText('name for each opening account');
    assert.deepEqual(this.submissions, []);
  });

  test('adds another opening account row', async function (assert) {
    await addAccount();
    assert.dom('[data-test-opening-account]').exists({ count: 2 });
    assert.dom(`${accountRow(2)} input[name="accountName"]`).hasValue('');
  });

  test('associates field help with the inputs', function (assert) {
    for (const [field, help] of [
      ['input[name="userName"]', 'signup-name-help'],
      ['input[name="email"]', 'signup-email-help'],
      ['input[name="password"]', 'signup-password-help'],
      ['input[name="accountName"]', 'opening-name-help'],
      ['select[name="accountType"]', 'opening-type-help'],
      ['input[name="initialDeposit"]', 'opening-deposit-help'],
    ]) {
      assert.dom(field).hasAttribute('aria-describedby', help);
      assert.dom(field).hasAttribute('title');
      assert.dom(`#${help}`).exists();
    }
  });

  test('removes a row and keeps the remaining account values', async function (assert) {
    await fillUser();
    await fillAccount(1, { name: 'First', type: 'checking', deposit: '0' });
    await addAccount();
    await fillAccount(2, { name: 'Remove me' });
    await removeAccount(2);

    assert.dom('[data-test-opening-account]').exists({ count: 1 });
    assert.dom('input[name="accountName"]').hasValue('First');
    await submitSignUp();
    assert.deepEqual(this.submissions[0].accounts, [
      { name: 'First', accountType: 'checking', initialDeposit: '0' },
    ]);
  });

  test('submits added accounts in visible order', async function (assert) {
    await fillUser();
    await fillAccount(1, { name: 'First', type: 'checking', deposit: '0' });
    await addAccount();
    await fillAccount(2, { name: 'Second', type: 'savings', deposit: '2.50' });
    await submitSignUp();

    assert.deepEqual(this.submissions[0].accounts, [
      { name: 'First', accountType: 'checking', initialDeposit: '0' },
      { name: 'Second', accountType: 'savings', initialDeposit: '2.50' },
    ]);
  });
});
