import { ACCOUNT_FIXTURE, buildAccountSummary } from './accounts-fixtures';

// Keep queued list responses for stale-read acceptance cases.
export function handleAccountRequest(path, state) {
  if (path === '/accounts') {
    return (
      state.accountLists.shift() ?? {
        accounts:
          state.currentUser === state.registeredUser
            ? state.registeredAccounts
            : [ACCOUNT_FIXTURE],
      }
    );
  }
  if (path === '/accounts/1') return buildAccountSummary();
  throw new Error(`Unexpected account API request: ${path}`);
}
