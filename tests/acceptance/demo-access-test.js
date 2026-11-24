import { click, currentURL, find, fillIn, visit } from '@ember/test-helpers';
import { module, test } from 'qunit';
import { setupApplicationTest } from 'accounts-dashboard/tests/helpers';
import {
  addAccount,
  fillAccount,
  fillUser,
  removeAccount,
  submitSignUp,
} from 'accounts-dashboard/tests/helpers/demo-sign-up-form';

module('Acceptance | Demo access', function (hooks) {
  setupApplicationTest(hooks);

  test('redirects a direct preview visit to sign in', async function (assert) {
    await visit('/demo-accounts');
    assert.strictEqual(currentURL(), '/sign-in');
  });

  test('keeps incorrect demo credentials on sign in', async function (assert) {
    await visit('/sign-in');
    await fillIn('input[name="email"]', 'alex@example.test');
    await fillIn('input[name="password"]', 'wrong-password');
    await click('button[type="submit"]');

    assert.strictEqual(currentURL(), '/sign-in');
    assert
      .dom('[role="alert"]')
      .includesText('Enter the demo email and password');
  });

  test('signs in with demo credentials and shows dummy accounts', async function (assert) {
    await visit('/sign-in');
    await fillIn('input[name="email"]', 'alex@example.test');
    await fillIn('input[name="password"]', 'mock-password');
    await click('button[type="submit"]');

    assert.strictEqual(currentURL(), '/demo-accounts');
    assert.dom('h1').hasText('Welcome, Alex Morgan');
    assert.dom('[data-test-demo-account]').exists({ count: 2 });
    assert.dom('[data-test-demo-account]:first-child').includesText('$100.00');
  });

  test('creates a demo user with exact opening balances', async function (assert) {
    await visit('/sign-in');
    await click('a[href="/sign-up"]');
    await fillUser();
    await fillAccount(1, {
      name: 'My checking',
      type: 'checking',
      deposit: '0',
    });
    await addAccount();
    await fillAccount(2, {
      name: 'Rainy day',
      type: 'savings',
      deposit: '25.1',
    });
    await submitSignUp();

    assert.strictEqual(currentURL(), '/demo-accounts');
    assert.dom('h1').hasText('Welcome, Taylor Morgan');
    assert.dom('[data-test-demo-account]').exists({ count: 2 });
    assert
      .dom('[data-test-demo-account]:first-child')
      .includesText('My checking');
    assert.dom('[data-test-demo-account]:first-child').includesText('$0.00');
    assert.dom('[data-test-demo-account]:last-child').includesText('savings');
    assert.dom('[data-test-demo-account]:last-child').includesText('$25.10');
  });

  test('keeps an incomplete sign-up on the form', async function (assert) {
    await visit('/sign-up');
    await fillUser();
    await submitSignUp();

    assert.strictEqual(currentURL(), '/sign-up');
    assert.true(find('input[name="accountName"]').validity.valueMissing);
  });

  test('keeps a negative deposit on the form', async function (assert) {
    await visit('/sign-up');
    await fillUser();
    await fillAccount(1, { name: 'Checking', type: 'checking', deposit: '-5' });
    await submitSignUp();

    assert.strictEqual(currentURL(), '/sign-up');
    assert.dom('[role="status"]').includesText('nonnegative amount');
  });

  test('keeps an overprecision deposit on the form', async function (assert) {
    await visit('/sign-up');
    await fillUser();
    await fillAccount(1, {
      name: 'Checking',
      type: 'checking',
      deposit: '1.001',
    });
    await submitSignUp();

    assert.strictEqual(currentURL(), '/sign-up');
    assert.true(find('input[name="initialDeposit"]').validity.patternMismatch);
  });

  test('omits removed accounts from the preview', async function (assert) {
    await visit('/sign-up');
    await fillUser();
    await fillAccount(1, { name: 'Checking', type: 'checking', deposit: '0' });
    await addAccount();
    await fillAccount(2, { name: 'Discarded' });
    await removeAccount(2);
    assert.dom('[data-test-opening-account]').exists({ count: 1 });
    await submitSignUp();

    assert.strictEqual(currentURL(), '/demo-accounts');
    assert.dom('[data-test-demo-account]').exists({ count: 1 });
    assert.dom('main').doesNotIncludeText('Discarded');
  });
});
