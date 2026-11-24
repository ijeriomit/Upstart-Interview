import Service from '@ember/service';
import { setupTest } from 'accounts-dashboard/tests/helpers';
import { CREDENTIALS_KEY } from 'accounts-dashboard/services/user-api';

export const ACCOUNT = {
  id: '1',
  name: 'Everyday checking',
  balance: '10.10',
};

export function accountSummary(currentAccount = ACCOUNT) {
  return {
    account: currentAccount,
    totalCredits: '0.00',
    totalDebits: '0.00',
    transactions: [],
  };
}

export function setupApiServiceTest(hooks) {
  setupTest(hooks);

  hooks.beforeEach(function () {
    sessionStorage.setItem(
      CREDENTIALS_KEY,
      JSON.stringify({ email: 'alex@example.test', password: 'mock-password' }),
    );
    this.pushCalls = [];
    this.routes = [];
    const pushCalls = this.pushCalls;
    const routes = this.routes;

    this.owner.register(
      'service:store',
      class extends Service {
        unloadAll() {
          pushCalls.length = 0;
        }

        push(payload) {
          pushCalls.push(payload);
          return payload;
        }
      },
    );
    this.owner.register(
      'service:router',
      class extends Service {
        replaceWith(route) {
          routes.push(route);
        }
      },
    );

    this.userApi = this.owner.lookup('service:user-api');
    this.accountsApi = this.owner.lookup('service:accounts-api');
    this.transactionsApi = this.owner.lookup('service:transactions-api');
  });

  hooks.afterEach(function () {
    sessionStorage.removeItem(CREDENTIALS_KEY);
  });
}
