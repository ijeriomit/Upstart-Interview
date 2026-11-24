import Route from '@ember/routing/route';
import { service } from '@ember/service';

export default class DemoAccountsRoute extends Route {
  @service demoAccess;
  @service router;

  beforeModel() {
    // Direct visits have no in-memory preview to render, including after a
    // refresh, so send the visitor back to the demo sign-in screen.
    if (!this.demoAccess.preview) {
      this.router.replaceWith('sign-in');
    }
  }

  model() {
    return this.demoAccess.preview;
  }
}
