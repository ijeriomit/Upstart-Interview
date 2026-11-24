import EmberRouter from '@embroider/router';
import config from 'accounts-dashboard/config/environment';

export default class Router extends EmberRouter {
  location = config.locationType;
  rootURL = config.rootURL;
}

Router.map(function () {
  this.route('accounts', function () {
    this.route('show', { path: '/:account_id' });
  });
});
