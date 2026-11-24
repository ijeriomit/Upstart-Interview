import Component from '@glimmer/component';
import { action } from '@ember/object';
import { on } from '@ember/modifier';
import { tracked } from '@glimmer/tracking';

export default class SignInForm extends Component {
  @tracked error = '';

  @action
  async submit(event) {
    event.preventDefault();
    if (this.args.isSubmitting) return;

    const data = new FormData(event.currentTarget);
    this.error = '';

    try {
      await this.args.onSubmit({
        email: data.get('email').trim(),
        password: data.get('password'),
      });
    } catch (error) {
      this.error = error.message;
    }
  }

  <template>
    <form class="accounts-dashboard-form" {{on "submit" this.submit}}>
      <fieldset disabled={{@isSubmitting}}>
        <label>
          Email
          <input type="email" name="email" autocomplete="username" required />
        </label>
        <label>
          Password
          <input
            type="password"
            name="password"
            autocomplete="current-password"
            required
          />
        </label>
        <button class="accounts-dashboard-button" type="submit">
          {{if @isSubmitting "Signing in…" "Sign in"}}
        </button>
      </fieldset>
      {{#if this.error}}
        <p
          role="alert"
          class="accounts-dashboard-feedback accounts-dashboard-error"
        >{{this.error}}</p>
      {{/if}}
    </form>
  </template>
}
