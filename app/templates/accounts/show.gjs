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
  {{! Read the controller's model so a save updates the rendered summary. }}
  {{#let @controller.model as |summary|}}
    {{pageTitle summary.account.name}}
    <LinkTo @route="accounts.index" class="fieldwork-back-link">All accounts</LinkTo>
    <h1>{{summary.account.name}}</h1>

    <dl class="fieldwork-summary">
      <div class="fieldwork-card fieldwork-balance">
        <dt>Current balance</dt>
        <dd class="fieldwork-amount" data-test-balance>{{usd
            summary.account.balance
          }}</dd>
      </div>
      <div class="fieldwork-card">
        <dt>Total credits</dt>
        <dd class="fieldwork-amount">{{usd summary.totalCredits}}</dd>
      </div>
      <div class="fieldwork-card">
        <dt>Total debits</dt>
        <dd class="fieldwork-amount">{{usd summary.totalDebits}}</dd>
      </div>
    </dl>

    <div class="fieldwork-detail-grid">
      <section
        class="fieldwork-card"
        aria-labelledby="transaction-history-heading"
      >
        <h2 id="transaction-history-heading">Transaction history</h2>
        <ul class="fieldwork-history">
          {{#each summary.transactions as |entry|}}
            <li data-test-transaction>
              <div>
                <p class="fieldwork-entry-name">{{if
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
            <li class="fieldwork-history-empty">No transactions yet.</li>
          {{/each}}
        </ul>
      </section>
      <section
        class="fieldwork-card"
        aria-labelledby="transaction-form-heading"
      >
        <h2 id="transaction-form-heading">New transaction</h2>
        {{! Ember route templates receive the controller as a named argument. }}
        <TransactionForm @onSubmit={{@controller.recordTransaction}} />
      </section>
    </div>
  {{/let}}
</template>
