import { click, fillIn, find, render } from '@ember/test-helpers';
import { module, test } from 'qunit';
import SignInForm from 'accounts-dashboard/components/sign-in-form';
import { setupRenderingTest } from 'accounts-dashboard/tests/helpers';

module('Integration | Component | sign-in-form', function (hooks) {
  setupRenderingTest(hooks);

  test('validates the fields and submits through its callback', async function (assert) {
    const submitted = [];
    const onSubmit = (credentials) => submitted.push(credentials);
    await render(<template><SignInForm @onSubmit={{onSubmit}} /></template>);

    await fillIn('input[name="email"]', 'invalid-email');
    assert.true(find('input[name="email"]').validity.typeMismatch);
    assert.true(find('input[name="password"]').validity.valueMissing);
    await click('button[type="submit"]');
    assert.deepEqual(submitted, []);

    await fillIn('input[name="email"]', 'alex@example.test');
    await fillIn('input[name="password"]', 'mock-password');
    await click('button[type="submit"]');
    assert.deepEqual(submitted, [
      { email: 'alex@example.test', password: 'mock-password' },
    ]);
  });
});
