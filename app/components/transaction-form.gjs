import Component from '@glimmer/component';
import { action } from '@ember/object';
import { on } from '@ember/modifier';
import { tracked } from '@glimmer/tracking';

export default class TransactionForm extends Component {
  // Writing to tracked fields rerenders the parts of the template that use them.
  @tracked isSaving = false;
  @tracked error = '';
  @tracked success = '';

  @action
  async submit(event) {
    event.preventDefault();
    if (this.isSaving) return;

    // FormData captures the current input values as strings. A text input
    // with inputmode="decimal" gives mobile users the appropriate keyboard.
    const form = event.currentTarget;
    const data = new FormData(form);
    this.isSaving = true;
    this.error = '';
    this.success = '';

    try {
      await this.args.onSubmit({
        direction: data.get('direction'),
        amount: data.get('amount').trim(),
        description: data.get('description').trim(),
      });
      form.reset();
      this.success = 'Transaction recorded.';
    } catch (error) {
      this.error = error.message;
    } finally {
      this.isSaving = false;
    }
  }

  <template>
    <form class="accounts-dashboard-form" {{on "submit" this.submit}}>
      <fieldset disabled={{this.isSaving}}>
        <label>
          Type
          <select name="direction">
            <option value="credit">Credit</option>
            <option value="debit">Debit</option>
          </select>
        </label>
        <label>
          Amount in USD
          <input
            name="amount"
            inputmode="decimal"
            placeholder="0.00"
            maxlength="20"
            required
          />
        </label>
        <label>
          Description
          <span class="accounts-dashboard-optional">(optional)</span>
          <input name="description" maxlength="120" />
        </label>
        <button class="accounts-dashboard-button" type="submit">
          {{if this.isSaving "Recording…" "Record transaction"}}
        </button>
      </fieldset>
      {{#if this.error}}
        <p
          role="alert"
          class="accounts-dashboard-feedback accounts-dashboard-error"
        >{{this.error}}</p>
      {{/if}}
      {{#if this.success}}
        <p
          role="status"
          class="accounts-dashboard-feedback"
        >{{this.success}}</p>
      {{/if}}
    </form>
  </template>
}
