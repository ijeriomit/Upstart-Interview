export const USER_FIXTURE = Object.freeze({
  id: '1',
  name: 'Alex Morgan',
  email: 'alex@example.test',
});

export const ACCOUNT_FIXTURE = Object.freeze({
  id: '1',
  name: 'Everyday checking',
  balance: '10.10',
});

export function buildAccountSummary(currentAccount = ACCOUNT_FIXTURE) {
  return {
    account: currentAccount,
    totalCredits: '0.00',
    totalDebits: '0.00',
    transactions: [],
  };
}
