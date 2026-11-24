import AccountsApiService from 'accounts-dashboard/services/accounts-api';
import {
  ACCOUNT_FIXTURE,
  USER_FIXTURE,
  buildAccountSummary,
} from './accounts-fixtures';

export function setupAccountsApiStub(testContext) {
  testContext.submissions = [];
  testContext.accountLists = [];

  const submissions = testContext.submissions;
  const accountLists = testContext.accountLists;

  testContext.owner.register(
    'service:accounts-api',
    class extends AccountsApiService {
      async request(path, options) {
        switch (path) {
          case '/me':
            return { user: USER_FIXTURE };
          case '/accounts':
            return accountLists.shift() ?? { accounts: [ACCOUNT_FIXTURE] };
          case '/accounts/1':
            return buildAccountSummary();
          case '/accounts/1/transactions': {
            const { transaction } = JSON.parse(options.body);
            submissions.push({ path, method: options.method, transaction });
            if (transaction.amount === '0.201') {
              throw new Error('Enter a decimal amount with two decimal places.');
            }
            return {
              ...buildAccountSummary({ ...ACCOUNT_FIXTURE, balance: '10.30' }),
              totalCredits: '0.20',
              transactions: [
                {
                  ...transaction,
                  id: '2',
                  createdAt: '2026-01-02T12:00:00Z',
                },
              ],
            };
          }
          default:
            throw new Error(`Unexpected API request: ${path}`);
        }
      }
    },
  );
}
