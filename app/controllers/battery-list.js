import Controller from '@ember/controller';
import { tracked, cached } from '@glimmer/tracking';
import { action } from '@ember/object';

export default class BatteryListController extends Controller {
  @tracked searchText = '';
  @tracked selectedStatus = 'all';
  @tracked filterAttentionRequired = false;

  @action
  updateStatus(event) {
    this.selectedStatus = event.target.value;
  }

  @action
  saveAlertThreshold(batteryId, threshold) {
    this.model = this.model.map((battery) =>
      battery.id === batteryId
        ? { ...battery, alertThreshold: Number(threshold) }
        : battery,
    );
  }

  batteryChargeLow(battery) {
    return battery.chargePercent < battery.alertThreshold;
  }

  batteryIsOffline(battery) {
    return battery.status == 'offline';
  }
  batteryRequiresAttention(battery) {
    return this.batteryChargeLow(battery) || this.batteryIsOffline(battery);
  }

  get numberOfBatteries() {
    return this.model.length;
  }

  @cached
  get offlineCount() {
    let numOffline = 0;
    this.model.map((battery) => {
      if (this.batteryIsOffline(battery)) {
        numOffline++;
      }
    });
    return numOffline;
  }

  @cached
  get lowChargeCount() {
    let numLowCharge = 0;
    this.model.map((battery) => {
      if (this.batteryChargeLow(battery)) {
        numLowCharge++;
      }
    });
    return numLowCharge;
  }

  get filteredBatteries() {
    return this.model.filter((battery) => {
      const matchesName = battery.name
        .toLowerCase()
        .includes(this.searchText.toLowerCase());
      const matchesStatus =
        this.selectedStatus === 'all' || battery.status === this.selectedStatus;
      const requiresAttention = this.filterAttentionRequired
        ? this.batteryRequiresAttention(battery)
        : true;

      return matchesName && matchesStatus && requiresAttention;
    });
  }
}
