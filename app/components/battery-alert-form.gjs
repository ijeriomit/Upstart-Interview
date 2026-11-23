import Component from '@glimmer/component';
import { tracked } from '@glimmer/tracking';
import { action } from '@ember/object';
import { Input } from '@ember/component';

export default class BatteryAlertForm extends Component {
  @action
  submitForm(event) {
    event.preventDefault();
    this.validateThreshold();
    if (!this.thresholdInputError) {
      this.args.onSave(this.alertThreshold);
      this.args.onCancel();
    }
  }
  @action
  validateThreshold() {
    if (this.alertThreshold < 0 || this.alertThreshold > 100) {
      this.thresholdInputError = 'Threshold must be between 0 and 100.';
    } else {
      this.thresholdInputError = '';
    }
  }

  @tracked alertThreshold = this.args.battery.alertThreshold;
  @tracked thresholdInputError = '';

  <template>
    <form {{on "submit" this.submitForm}}>
      <label for="threshold-input">
        Alert Threshold:
      </label>
      <Input
        id="threshold-input"
        type="number"
        @value={{this.alertThreshold}}
        {{on "input" this.validateThreshold}}
      />
      {{#if this.thresholdInputError}}
        <p>
          {{this.thresholdInputError}}
        </p>
      {{/if}}
      <button type="submit">
        Save Alert
      </button>
      <button type="button" {{on "click" @onCancel}}>
        Cancel
      </button>
    </form>
  </template>
}
