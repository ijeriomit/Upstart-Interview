import { ACCOUNT_FIXTURE, buildAccountSummary } from './accounts-fixtures';

// Return the updated summary that Rails sends after a successful posting.
export function handleTransactionRequest(path, options, state) {
  const { transaction } = JSON.parse(options.body);
  state.submissions.push({ path, method: options.method, transaction });
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
