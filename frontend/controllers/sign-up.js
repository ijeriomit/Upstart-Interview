import Controller from '@ember/controller';
import { action } from '@ember/object';
import { service } from '@ember/service';

export default class SignUpController extends Controller {
  @service demoAccess;
  @service router;

  @action
  register({ user, accounts }) {
    // The form supplies validated account rows. This preview intentionally
    // retains only the name and accounts, then navigates to the demo screen.
    this.demoAccess.register({ name: user.name, accounts });
    return this.router.transitionTo('demo-accounts');
  }
}
