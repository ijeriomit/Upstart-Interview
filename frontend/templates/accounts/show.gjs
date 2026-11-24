import { LinkTo } from '@ember/routing';
import { pageTitle } from 'ember-page-title';
import TransactionForm from '../../components/transaction-form';
import usd from '../../helpers/usd';

const dateFormatter = new Intl.DateTimeFormat('en-US', { dateStyle: 'medium' });

function dateLabel(date) {
  return dateFormatter.format(new Date(date));
}

function signedUsd(direction, amount) {
  return (direction === 'credit' ? '+' : '−') + usd(amount);
}

<template>
  {{#let @model as |account|}}
    {{pageTitle account.name}}
    <LinkTo @route="accounts.index" class="accounts-dashboard-back-link">All
      accounts</LinkTo>
    <h1>{{account.name}}</h1>

    <dl class="accounts-dashboard-summary">
      <div class="accounts-dashboard-card accounts-dashboard-balance">
        <dt>Current balance</dt>
        <dd class="accounts-dashboard-amount" data-test-balance>{{usd
            account.balance
          }}</dd>
      </div>
      <div class="accounts-dashboard-card">
        <dt>Total credits</dt>
        <dd class="accounts-dashboard-amount">{{usd account.totalCredits}}</dd>
      </div>
      <div class="accounts-dashboard-card">
        <dt>Total debits</dt>
        <dd class="accounts-dashboard-amount">{{usd account.totalDebits}}</dd>
      </div>
    </dl>

    <div class="accounts-dashboard-detail-grid">
      <section
        class="accounts-dashboard-card"
        aria-labelledby="transaction-history-heading"
      >
        <h2 id="transaction-history-heading">Transaction history</h2>
        <ul class="accounts-dashboard-history">
          {{#each account.transactions as |entry|}}
            <li data-test-transaction>
              <div>
                <p class="accounts-dashboard-entry-name">{{if
                    entry.description
                    entry.description
                    entry.direction
                  }}</p>
                <time datetime={{entry.createdAt}}>{{dateLabel
                    entry.createdAt
                  }}</time>
              </div>
              <strong>{{signedUsd entry.direction entry.amount}}</strong>
            </li>
          {{else}}
            <li class="accounts-dashboard-history-empty">No transactions yet.</li>
          {{/each}}
        </ul>
      </section>
      <section
        class="accounts-dashboard-card"
        aria-labelledby="transaction-form-heading"
      >
        <h2 id="transaction-form-heading">New transaction</h2>
        {{! Ember route templates receive the controller as a named argument. }}
        <TransactionForm @onSubmit={{@controller.recordTransaction}} />
      </section>
    </div>
  {{/let}}
</template>
