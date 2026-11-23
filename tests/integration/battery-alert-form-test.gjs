import { module, test } from 'qunit';
import { render, fillIn, click } from '@ember/test-helpers';
import { setupRenderingTest } from 'battery-dashboard/tests/helpers';
import { makeBatteries } from 'battery-dashboard/tests/helpers/batteries';
import BatteryAlertForm from 'battery-dashboard/components/battery-alert-form';

module('Integration | Component | battery-alert-form', function (hooks) {
  setupRenderingTest(hooks);

  hooks.beforeEach(function () {
    this.battery = makeBatteries()[0];
    this.savedValues = [];
    this.closeCalls = 0;
    this.save = (threshold) => this.savedValues.push(threshold);
    this.close = () => this.closeCalls++;
  });

  test('editing and submitting reports the draft to the parent', async function (assert) {
    await render(<template>
      <BatteryAlertForm @battery={{this.battery}} @onSave={{this.save}} @onCancel={{this.close}} />
    </template>);

    assert.dom('#threshold-input').hasValue('20');
    await fillIn('#threshold-input', '35');
    await click('button[type="submit"]');

    assert.deepEqual(this.savedValues, ['35'], 'The input supplies text; the controller converts it');
    assert.strictEqual(this.closeCalls, 1);
    assert.strictEqual(this.battery.alertThreshold, 20, 'The form does not mutate incoming data');
  });

  test('out-of-range input prevents saving and closing', async function (assert) {
    await render(<template>
      <BatteryAlertForm @battery={{this.battery}} @onSave={{this.save}} @onCancel={{this.close}} />
    </template>);

    await fillIn('#threshold-input', '101');
    await click('button[type="submit"]');

    assert.dom('form p').hasText('Threshold must be between 0 and 100.');
    assert.deepEqual(this.savedValues, []);
    assert.strictEqual(this.closeCalls, 0);

    await fillIn('#threshold-input', '50');
    await click('button[type="submit"]');
    assert.deepEqual(this.savedValues, ['50'], 'Correcting the input allows saving');
  });

  test('cancel closes without saving the draft', async function (assert) {
    await render(<template>
      <BatteryAlertForm @battery={{this.battery}} @onSave={{this.save}} @onCancel={{this.close}} />
    </template>);

    await fillIn('#threshold-input', '70');
    await click('button[type="button"]');

    assert.deepEqual(this.savedValues, []);
    assert.strictEqual(this.closeCalls, 1);
    assert.strictEqual(this.battery.alertThreshold, 20);
  });
});
