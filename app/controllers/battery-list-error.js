import Controller from '@ember/controller';
import { action } from '@ember/object';
import { service } from '@ember/service';

export default class BatteryListErrorController extends Controller {
  @service router;

  @action
  retry() {
    this.router.transitionTo('battery-list');
  }
}
