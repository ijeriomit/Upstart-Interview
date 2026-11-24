function resource(type, { id, ...attributes }) {
  return { type, id, attributes };
}

export function normalizeCurrentUser({ user }) {
  return { data: resource('user', user) };
}

export function normalizeAccountList({ accounts }) {
  return {
    data: accounts.map(({ id, name, balance }) =>
      resource('account', { id, name, balance }),
    ),
  };
}

export function normalizeAccountSummary({
  account,
  totalCredits,
  totalDebits,
  transactions,
}) {
  const included = transactions.map((entry) => resource('transaction', entry));

  // Rails returns the full ordered history with each summary.
  return {
    data: {
      ...resource('account', { ...account, totalCredits, totalDebits }),
      relationships: {
        transactions: {
          data: included.map(({ type, id }) => ({ type, id })),
        },
      },
    },
    included,
  };
}
