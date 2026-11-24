import { click, fillIn, select } from '@ember/test-helpers';

export const accountRow = (index) =>
  `[data-test-opening-account]:nth-of-type(${index})`;

export async function fillUser({
  name = 'Taylor Morgan',
  email = 'taylor@example.test',
  password = 'demo-password',
} = {}) {
  await fillIn('input[name="userName"]', name);
  await fillIn('input[name="email"]', email);
  await fillIn('input[name="password"]', password);
}

export async function fillAccount(index, { name, type, deposit } = {}) {
  const row = accountRow(index);
  if (name !== undefined)
    await fillIn(`${row} input[name="accountName"]`, name);
  if (type !== undefined)
    await select(`${row} select[name="accountType"]`, type);
  if (deposit !== undefined) {
    await fillIn(`${row} input[name="initialDeposit"]`, deposit);
  }
}

export async function addAccount() {
  await click('[data-test-add-account]');
}

export async function removeAccount(index) {
  await click(`${accountRow(index)} [data-test-remove-account]`);
}

export async function submitSignUp() {
  await click('button[type="submit"]');
}
