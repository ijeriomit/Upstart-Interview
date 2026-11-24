import Component from '@glimmer/component';
import { action } from '@ember/object';
import { on } from '@ember/modifier';
import { LinkTo } from '@ember/routing';
import { service } from '@ember/service';
import { tracked } from '@glimmer/tracking';

export default class Menu extends Component {
  @service userApi;
  @tracked isOpen = false;
  @tracked signOutError = '';

  @action
  toggleMenu() {
    this.isOpen = !this.isOpen;
  }

  @action
  closeMenu() {
    this.isOpen = false;
  }

  @action
  dismiss(event) {
    if (event.key === 'Escape' && this.isOpen) {
      this.closeMenu();
      this.#toggleFor(event.currentTarget).focus();
    }
  }

  @action
  async signOut(event) {
    const toggle = this.#toggleFor(event.currentTarget);
    this.signOutError = '';

    try {
      await this.userApi.signOut();
      this.closeMenu();
      toggle.focus();
    } catch (error) {
      this.signOutError = error.message;
    }
  }

  #toggleFor(element) {
    return element
      .closest('.accounts-dashboard-menu')
      .querySelector('.accounts-dashboard-menu-toggle');
  }

  <template>
    <div class="accounts-dashboard-menu">
      <button
        type="button"
        class="accounts-dashboard-menu-toggle"
        aria-expanded={{if this.isOpen "true" "false"}}
        {{on "click" this.toggleMenu}}
        {{on "keydown" this.dismiss}}
      ><span aria-hidden="true">☰</span> Menu</button>
      {{#if this.isOpen}}
        <nav aria-label="Account menu" class="accounts-dashboard-menu-panel">
          {{#if this.userApi.currentUser}}
            <p><strong>{{this.userApi.currentUser.name}}</strong></p>
            <button
              type="button"
              class="accounts-dashboard-button"
              disabled={{this.userApi.isChangingSession}}
              {{on "click" this.signOut}}
              {{on "keydown" this.dismiss}}
            >Sign out</button>
            {{#if this.signOutError}}
              <p
                role="alert"
                class="accounts-dashboard-error"
              >{{this.signOutError}}</p>
            {{/if}}
          {{else}}
            <LinkTo
              @route="sign-in"
              {{on "click" this.closeMenu}}
              {{on "keydown" this.dismiss}}
            >Sign in</LinkTo>
            <LinkTo
              @route="sign-up"
              {{on "click" this.closeMenu}}
              {{on "keydown" this.dismiss}}
            >Sign up</LinkTo>
          {{/if}}
        </nav>
      {{/if}}
    </div>
  </template>
}
