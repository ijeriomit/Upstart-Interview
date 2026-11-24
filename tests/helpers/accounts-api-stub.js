import AccountsApiService, {
  CREDENTIALS_KEY,
} from 'accounts-dashboard/services/accounts-api';
import {
  ACCOUNT_FIXTURE,
  USER_FIXTURE,
  buildAccountSummary,
} from './accounts-fixtures';

export function setupAccountsApiStub(testContext, { signedIn = true } = {}) {
  if (signedIn) {
    sessionStorage.setItem(
      CREDENTIALS_KEY,
      JSON.stringify({ email: USER_FIXTURE.email, password: 'mock-password' }),
    );
  } else {
    sessionStorage.removeItem(CREDENTIALS_KEY);
  }
  testContext.submissions = [];
  testContext.accountLists = [];
  testContext.apiRequests = [];
  testContext.registrations = [];

  const submissions = testContext.submissions;
  const accountLists = testContext.accountLists;
  const apiRequests = testContext.apiRequests;
  const registrations = testContext.registrations;
  let currentUser = signedIn ? USER_FIXTURE : null;
  let registeredUser;
  let registeredPassword;
  let registeredAccounts = [];

  testContext.owner.register(
    'service:accounts-api',
    class extends AccountsApiService {
      async request(path, options) {
        apiRequests.push(path);
        switch (path) {
          case '/me':
            if (!currentUser) {
              throw Object.assign(new Error('Sign in required.'), {
                status: 401,
              });
            }
            return { user: currentUser };
          case '/session': {
            const { session } = JSON.parse(options.body);
            const existingLogin =
              session.email === USER_FIXTURE.email &&
              session.password === 'mock-password';
            const newLogin =
              session.email === registeredUser?.email &&
              session.password === registeredPassword;
            if (!existingLogin && !newLogin) {
              throw Object.assign(new Error('Invalid email or password.'), {
                status: 401,
              });
            }
            currentUser = newLogin ? registeredUser : USER_FIXTURE;
            return { user: currentUser };
          }
          case '/users': {
            const registration = JSON.parse(options.body);
            registrations.push(registration);
            if (registration.user.email === USER_FIXTURE.email) {
              throw Object.assign(new Error('Email has already been taken.'), {
                status: 422,
              });
            }
            registeredUser = {
              id: '3',
              name: registration.user.name,
              email: registration.user.email,
            };
            registeredPassword = registration.user.password;
            registeredAccounts = registration.accounts.map(
              (account, index) => ({
                id: String(index + 3),
                name: account.name,
                balance: Number(account.initialDeposit).toFixed(2),
              }),
            );
            return { user: registeredUser };
          }
          case '/accounts':
            return (
              accountLists.shift() ?? {
                accounts:
                  currentUser === registeredUser
                    ? registeredAccounts
                    : [ACCOUNT_FIXTURE],
              }
            );
          case '/accounts/1':
            return buildAccountSummary();
          case '/accounts/1/transactions': {
            const { transaction } = JSON.parse(options.body);
            submissions.push({ path, method: options.method, transaction });
            if (transaction.amount === '0.201') {
              throw new Error(
                'Enter a decimal amount with two decimal places.',
              );
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
