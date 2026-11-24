import Controller from '@ember/controller';
import { action } from '@ember/object';
import { service } from '@ember/service';
import { tracked } from '@glimmer/tracking';

export default class SignInController extends Controller {
  @service demoAccess;
  @service router;
  @tracked isSubmitting = false;

  @action
  async signIn(credentials) {
    this.isSubmitting = true;
    try {
      this.demoAccess.signIn(credentials);
      await this.router.transitionTo('demo-accounts');
    } finally {
      this.isSubmitting = false;
    }
  }
}
