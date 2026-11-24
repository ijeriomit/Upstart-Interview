import { click, currentURL, fillIn, visit } from '@ember/test-helpers';
import { module, test } from 'qunit';
import { setupApplicationTest } from 'accounts-dashboard/tests/helpers';
import { setupAccountsApiStub } from 'accounts-dashboard/tests/helpers/accounts-api-stub';
import { USER_FIXTURE } from 'accounts-dashboard/tests/helpers/accounts-fixtures';

module('Acceptance | Session', function (hooks) {
  setupApplicationTest(hooks);

  test('redirects a signed-out deep link and signs in from the public form', async function (assert) {
    setupAccountsApiStub(this, { signedIn: false });

    await visit('/accounts/1');

    assert.strictEqual(currentURL(), '/sign-in');
    assert.deepEqual(this.apiRequests, [], 'no protected data was loaded');
    await click('[aria-expanded]');
    assert.dom('nav a[href="/sign-in"]').hasText('Sign in');
    assert.dom('nav button').doesNotExist();
    await click('nav a[href="/sign-in"]');

    await fillIn('input[name="email"]', USER_FIXTURE.email);
    await fillIn('input[name="password"]', 'wrong-password');
    await click('main button[type="submit"]');
    assert.dom('[role="alert"]').hasText('Invalid email or password.');
    assert.strictEqual(currentURL(), '/sign-in');

    await fillIn('input[name="password"]', 'mock-password');
    await click('main button[type="submit"]');
    assert.strictEqual(currentURL(), '/accounts');
    assert.dom('main').includesText('Everyday checking');
    await click('[aria-expanded]');
    assert.dom('nav button').hasText('Sign out');
    assert.dom('nav a[href="/sign-in"]').doesNotExist();
  });

  test('restores an existing session on application boot and clears its records on sign-out', async function (assert) {
    setupAccountsApiStub(this);

    await visit('/accounts/1');
    assert.deepEqual(this.apiRequests.slice(0, 2), ['/me', '/accounts/1']);
    assert.dom('[data-test-balance]').hasText('$10.10');
    await fillIn('input[name="amount"]', '0.20');
    await click('main button[type="submit"]');

    const store = this.owner.lookup('service:store');
    const hasCachedRecord = (type, id) => {
      // eslint-disable-next-line warp-drive/no-legacy-request-patterns -- Inspect the legacy store without loading records from the API.
      return Boolean(store.peekRecord(type, id));
    };
    assert.true(hasCachedRecord('transaction', '2'));
    await click('[aria-expanded]');
    assert.dom('nav strong').hasText(USER_FIXTURE.name);
    await click('nav button');

    assert.strictEqual(currentURL(), '/sign-in');
    assert.dom('[data-test-balance]').doesNotExist();
    assert.false(hasCachedRecord('user', USER_FIXTURE.id));
    assert.false(hasCachedRecord('account', '1'));
    assert.false(hasCachedRecord('transaction', '2'));
    await click('[aria-expanded]');
    assert.dom('nav a[href="/sign-in"]').hasText('Sign in');
  });
});
