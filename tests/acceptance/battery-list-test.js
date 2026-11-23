import { module, test } from 'qunit';
import Service from '@ember/service';
import { visit, currentURL, fillIn, click } from '@ember/test-helpers';
import { setupApplicationTest } from 'battery-dashboard/tests/helpers';
import { makeBatteries } from 'battery-dashboard/tests/helpers/batteries';

module('Acceptance | battery dashboard', function (hooks) {
  setupApplicationTest(hooks);

  hooks.beforeEach(function () {
    // Replace only the network boundary; exercise real routes, controllers and components.
    this.owner.register('service:battery-api', class extends Service {
      async getBatteries() {
        return makeBatteries();
      }
    });
  });

  test('search and status filter the loaded page together', async function (assert) {
    await visit('/battery-list');
    assert.strictEqual(currentURL(), '/battery-list');
    assert.dom('.battery-card').exists({ count: 3 });

    await fillIn('#bat-search', 'HOME');
    assert.dom('.battery-card').exists({ count: 1 });
    assert.dom('.battery-card h2').hasText('Home');

    await fillIn('#bat-status', 'offline');
    assert.dom('.battery-card').doesNotExist();
    assert.dom().includesText('No matching batteries.');

    await fillIn('#bat-search', '');
    assert.dom('.battery-card').exists({ count: 1 });
    assert.dom('.battery-card h2').hasText('Cabin');
  });

  test('saved thresholds survive filtering and reopening the form', async function (assert) {
    await visit('/battery-list');
    await fillIn('#bat-search', 'Home');
    await click('.battery-card button');
    await fillIn('#threshold-input', '90');
    await click('button[type="submit"]');

    assert.dom('.battery-card form').doesNotExist();
    assert.dom('.battery-card .alert').includesText('90%');

    await fillIn('#bat-search', 'Garage');
    await click('.battery-card button');
    assert.dom('#threshold-input').hasValue('20', 'Other batteries keep their settings');
    await click('form button[type="button"]');

    await fillIn('#bat-search', 'Home');
    await click('.battery-card button');
    assert.dom('#threshold-input').hasValue('90', 'Saved state survives card destruction');
  });

  test('invalid threshold keeps the form open and saved data unchanged', async function (assert) {
    await visit('/battery-list');
    await fillIn('#bat-search', 'Home');
    await click('.battery-card button');
    await fillIn('#threshold-input', '-1');
    await click('button[type="submit"]');

    assert.dom('.battery-card form').exists();
    assert.dom('form p').hasText('Threshold must be between 0 and 100.');
    await click('form button[type="button"]');
    await click('.battery-card button');
    assert.dom('#threshold-input').hasValue('20');
  });
});
