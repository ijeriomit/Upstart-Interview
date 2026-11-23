import { module, test } from 'qunit';
import { setupTest } from 'battery-dashboard/tests/helpers';
import { makeBatteries } from 'battery-dashboard/tests/helpers/batteries';

module('Unit | Controller | battery-list', function (hooks) {
  setupTest(hooks);

  hooks.beforeEach(function () {
    this.controller = this.owner.lookup('controller:battery-list');
    this.controller.model = makeBatteries();
  });

  test('search is case insensitive and combines with status', function (assert) {
    this.controller.searchText = 'HOME';
    assert.deepEqual(this.controller.filteredBatteries.map((battery) => battery.id), ['1']);

    this.controller.selectedStatus = 'offline';
    assert.deepEqual(this.controller.filteredBatteries, [], 'Both criteria must match');

    this.controller.searchText = '';
    assert.deepEqual(this.controller.filteredBatteries.map((battery) => battery.id), ['3']);
  });

  test('saving replaces only the selected battery and converts input to a number', function (assert) {
    const original = this.controller.model;
    this.controller.saveAlertThreshold('1', '35');

    assert.strictEqual(this.controller.model[0].alertThreshold, 35);
    assert.notStrictEqual(this.controller.model, original);
    assert.notStrictEqual(this.controller.model[0], original[0]);
    assert.strictEqual(original[0].alertThreshold, 20, 'Previous state is preserved');
    assert.strictEqual(this.controller.model[1], original[1], 'Other batteries are unchanged');
  });

  test('empty data produces empty results', function (assert) {
    this.controller.model = [];
    assert.deepEqual(this.controller.filteredBatteries, []);
  });
});
