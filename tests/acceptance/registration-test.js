import { click, currentURL, fillIn, visit } from '@ember/test-helpers';
import { module, test } from 'qunit';
import { setupApplicationTest } from 'accounts-dashboard/tests/helpers';
import { setupAccountsApiStub } from 'accounts-dashboard/tests/helpers/accounts-api-stub';
import {
  addAccount,
  fillAccount,
  fillUser,
  removeAccount,
  submitSignUp,
} from 'accounts-dashboard/tests/helpers/sign-up-form';

module('Acceptance | Registration', function (hooks) {
  setupApplicationTest(hooks);

  hooks.beforeEach(function () {
    setupAccountsApiStub(this, { signedIn: false });
  });

  test('registers opening accounts, then signs in to see persisted balances', async function (assert) {
    await visit('/sign-up');
    await fillUser();
    await fillAccount(1, { name: 'Daily', type: 'checking', deposit: '0' });
    await addAccount();
    await fillAccount(2, {
      name: 'Rainy day',
      type: 'savings',
      deposit: '25.10',
    });
    await submitSignUp();

    assert.strictEqual(currentURL(), '/sign-in');
    assert.deepEqual(this.registrations[0].accounts, [
      { name: 'Daily', accountType: 'checking', initialDeposit: '0' },
      { name: 'Rainy day', accountType: 'savings', initialDeposit: '25.10' },
    ]);

    await fillIn('input[name="email"]', 'taylor@example.test');
    await fillIn('input[name="password"]', 'demo-password');
    await click('main button[type="submit"]');
    assert.strictEqual(currentURL(), '/accounts');
    assert.dom('main').includesText('Daily');
    assert.dom('main').includesText('$0.00');
    assert.dom('main').includesText('Rainy day');
    assert.dom('main').includesText('$25.10');
  });

  test('keeps invalid fields on the form without posting', async function (assert) {
    await visit('/sign-up');
    await fillUser();
    await fillAccount(1, { name: 'Daily', type: 'checking', deposit: '-1' });
    await submitSignUp();

    assert.strictEqual(currentURL(), '/sign-up');
    assert.dom('[role="status"]').includesText('nonnegative amount');
    assert.deepEqual(this.registrations, []);
  });

  test('shows a Rails validation error without losing the form', async function (assert) {
    await visit('/sign-up');
    await fillUser({ email: 'alex@example.test' });
    await fillAccount(1, { name: 'Daily', type: 'checking', deposit: '0' });
    await submitSignUp();

    assert.strictEqual(currentURL(), '/sign-up');
    assert.dom('[role="alert"]').includesText('Email has already been taken');
    assert.dom('input[name="accountName"]').hasValue('Daily');
  });

  test('does not send a removed opening account', async function (assert) {
    await visit('/sign-up');
    await fillUser();
    await fillAccount(1, { name: 'Daily', type: 'checking', deposit: '0' });
    await addAccount();
    await fillAccount(2, { name: 'Discarded' });
    await removeAccount(2);
    await submitSignUp();

    assert.deepEqual(
      this.registrations[0].accounts.map(({ name }) => name),
      ['Daily'],
    );
  });
});
