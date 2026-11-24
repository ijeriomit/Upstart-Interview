import UserApiService, {
  CREDENTIALS_KEY,
} from 'accounts-dashboard/services/user-api';
import { USER_FIXTURE } from './accounts-fixtures';
import { handleUserRequest } from './user-api-stub';
import { handleAccountRequest } from './account-api-stub';
import { handleTransactionRequest } from './transaction-api-stub';

// One setup helper registers a fake transport; endpoint behavior lives in
// separate handlers so each API area can change without growing this file.
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

  const state = {
    currentUser: signedIn ? USER_FIXTURE : null,
    registeredUser: null,
    registeredPassword: null,
    registeredAccounts: [],
    submissions: testContext.submissions,
    accountLists: testContext.accountLists,
    apiRequests: testContext.apiRequests,
    registrations: testContext.registrations,
  };

  testContext.owner.register(
    'service:user-api',
    class extends UserApiService {
      async request(path, options) {
        state.apiRequests.push(path);
        if (['/me', '/session', '/users'].includes(path)) {
          return handleUserRequest(path, options, state);
        }
        if (path === '/accounts' || path === '/accounts/1') {
          return handleAccountRequest(path, state);
        }
        if (path === '/accounts/1/transactions') {
          return handleTransactionRequest(path, options, state);
        }
        throw new Error(`Unexpected API request: ${path}`);
      }
    },
  );
}
