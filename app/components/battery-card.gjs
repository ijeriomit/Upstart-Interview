import Component from '@glimmer/component';
import { tracked } from '@glimmer/tracking';
import { action } from '@ember/object';
import BatteryAlertForm from './battery-alert-form';

export default class BatteryCard extends Component {
  @tracked showForm = false;

  @action
  toggleForm(value = null) {
    this.showForm = value ?? !this.showForm;
  }
  @action
  updateAlertThreshold(newThreshold) {
    this.args.onSave(this.args.battery.id, newThreshold);
  }

  get batteryStatus() {
    return this.args.battery?.status ?? 'offline';
  }

  get batteryCharge() {
    return this.args.battery?.chargePercent ?? 0;
  }
  get belowAlertThreshold() {
    return (
      this.args.battery?.chargePercent <= this.args.battery?.alertThreshold
    );
  }

  <template>
    <article class="battery-card">
      <h2>{{@battery.name}}</h2>
      <h2>Battery Status</h2>
      <p>{{this.batteryStatus}}</p>
      <h2>Battery Charge</h2>
      <p>{{this.batteryCharge}}%</p>
      {{#if this.belowAlertThreshold}}
        <p class="alert">
          {{@battery.name}}: Battery is below
          {{@battery.alertThreshold}}% !</p>
      {{/if}}
      <button type="button" {{on "click" this.toggleForm}}>
        Configure Alerts
      </button>
      <p>
        Alert:
        {{@battery.alertThreshold}}
      </p>
      {{#if this.showForm}}
        <BatteryAlertForm
          @battery={{@battery}}
          @onSave={{this.updateAlertThreshold}}
          @onCancel={{(fn this.toggleForm false)}}
        />
      {{/if}}
    </article>
  </template>
}
