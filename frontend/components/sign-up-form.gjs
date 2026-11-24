import Component from '@glimmer/component';
import { action } from '@ember/object';
import { fn } from '@ember/helper';
import { on } from '@ember/modifier';
import { tracked } from '@glimmer/tracking';

export default class SignUpForm extends Component {
  // Row IDs are stable even after removal, so Ember keeps each row's input state
  // attached to the correct account when the list changes.
  @tracked openingAccounts = [{ id: 1, invalidDeposit: false }];
  @tracked error = '';
  @tracked isSubmitting = false;

  #nextAccountId = 2;

  get canRemoveAccount() {
    return this.openingAccounts.length > 1;
  }

  @action
  addAccount() {
    this.openingAccounts = [
      ...this.openingAccounts,
      { id: this.#nextAccountId++, invalidDeposit: false },
    ];
  }

  @action
  removeAccount(id) {
    if (!this.canRemoveAccount) return;
    this.openingAccounts = this.openingAccounts.filter(
      (account) => account.id !== id,
    );
  }

  @action
  validateDeposit(id, event) {
    // Native pattern validation blocks submit; this tracked flag also gives
    // the user immediate feedback while they edit a deposit.
    const { patternMismatch } = event.currentTarget.validity;
    this.openingAccounts = this.openingAccounts.map((account) =>
      account.id === id
        ? { ...account, invalidDeposit: patternMismatch }
        : account,
    );
  }

  @action
  async submit(event) {
    event.preventDefault();
    if (this.isSubmitting) return;

    const data = new FormData(event.currentTarget);
    const name = data.get('userName').trim();
    // FormData returns repeated field names in DOM order, matching the order
    // of the account rows that the user currently sees.
    const accountTypes = data.getAll('accountType');
    const deposits = data.getAll('initialDeposit');
    const accounts = data.getAll('accountName').map((accountName, index) => ({
      name: accountName.trim(),
      accountType: accountTypes[index],
      initialDeposit: deposits[index],
    }));

    if (!name || accounts.some((account) => !account.name)) {
      this.error = 'Enter your name and a name for each opening account.';
      return;
    }

    this.isSubmitting = true;
    this.error = '';
    try {
      await this.args.onSubmit({
        user: {
          name,
          email: data.get('email').trim(),
          password: data.get('password'),
        },
        accounts,
      });
    } catch (error) {
      this.error = error.message;
    } finally {
      this.isSubmitting = false;
    }
  }

  <template>
    <form class="accounts-dashboard-form" {{on "submit" this.submit}}>
      <fieldset disabled={{this.isSubmitting}}>
        <label>
          Your name
          <input
            name="userName"
            autocomplete="name"
            title="Enter the name to show on your demo accounts."
            aria-describedby="signup-name-help"
            required
          />
        </label>
        <p id="signup-name-help" class="accounts-dashboard-optional">
          This name appears on your demo account preview.
        </p>
        <label>
          Email
          <input
            type="email"
            name="email"
            autocomplete="email"
            title="Use an email address for this demo form."
            aria-describedby="signup-email-help"
            required
          />
        </label>
        <p id="signup-email-help" class="accounts-dashboard-optional">
          Use an email address for this demo form.
        </p>
        <label>
          Demo password
          <input
            type="password"
            name="password"
            autocomplete="new-password"
            title="Use a made-up password; this preview does not save it."
            aria-describedby="signup-password-help"
            required
          />
        </label>
        <p id="signup-password-help" class="accounts-dashboard-optional">
          Use a made-up password. This preview does not save it.
        </p>
        <h2>Opening accounts</h2>
        <p id="opening-name-help" class="accounts-dashboard-optional">
          Give each account a name that helps you recognize it.
        </p>
        <p id="opening-type-help" class="accounts-dashboard-optional">
          Choose checking, savings, or credit.
        </p>
        <p id="opening-deposit-help" class="accounts-dashboard-optional">
          Enter a USD amount with up to two decimal places. A deposit of $0 is
          allowed.
        </p>
        {{#each this.openingAccounts key="id" as |account|}}
          <fieldset
            class="accounts-dashboard-opening-account"
            data-test-opening-account
          >
            <legend>Opening account</legend>
            <label>
              Account name
              <input
                name="accountName"
                title="Give this account a recognizable name."
                aria-describedby="opening-name-help"
                required
              />
            </label>
            <label>
              Account type
              <select
                name="accountType"
                title="Choose checking, savings, or credit."
                aria-describedby="opening-type-help"
                required
              >
                <option value="">Choose an account type</option>
                <option value="checking">Checking</option>
                <option value="savings">Savings</option>
                <option value="credit">Credit</option>
              </select>
            </label>
            <label>
              Initial deposit in USD
              <input
                name="initialDeposit"
                inputmode="decimal"
                placeholder="0.00"
                pattern="[0-9]{1,17}([.][0-9]{1,2})?"
                title="Enter a nonnegative USD amount with up to two decimal places."
                aria-describedby="opening-deposit-help"
                aria-invalid={{if account.invalidDeposit "true"}}
                required
                {{on "input" (fn this.validateDeposit account.id)}}
              />
            </label>
            {{#if account.invalidDeposit}}
              <p class="accounts-dashboard-error" role="status">
                Enter a nonnegative amount with up to two decimal places.
              </p>
            {{/if}}
            {{#if this.canRemoveAccount}}
              <button
                type="button"
                data-test-remove-account
                {{on "click" (fn this.removeAccount account.id)}}
              >
                Remove account
              </button>
            {{/if}}
          </fieldset>
        {{/each}}
        <button
          type="button"
          data-test-add-account
          {{on "click" this.addAccount}}
        >Add another account</button>
        <button type="submit" class="accounts-dashboard-button">
          {{if this.isSubmitting "Creating…" "Create demo user"}}
        </button>
      </fieldset>
      {{#if this.error}}
        <p
          class="accounts-dashboard-feedback accounts-dashboard-error"
          role="alert"
        >{{this.error}}</p>
      {{/if}}
    </form>
  </template>
}
