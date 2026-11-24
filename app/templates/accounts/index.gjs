import { LinkTo } from '@ember/routing';
import { pageTitle } from 'ember-page-title';
import usd from '../../helpers/usd';

<template>
  {{pageTitle "Accounts"}}
  <h1>Accounts</h1>
  <p class="accounts-dashboard-intro">Review your balances and account activity.</p>
  <ul class="accounts-dashboard-account-grid">
    {{#each @model as |account|}}
      <li class="accounts-dashboard-card">
        <h2>{{account.name}}</h2>
        <p class="accounts-dashboard-label">Current balance</p>
        <p class="accounts-dashboard-amount">{{usd account.balance}}</p>
        <LinkTo
          @route="accounts.show"
          @model={{account.id}}
          class="accounts-dashboard-card-link"
        >
          View
          {{account.name}}
        </LinkTo>
      </li>
    {{else}}
      <li class="accounts-dashboard-card">You have no accounts yet.</li>
    {{/each}}
  </ul>
</template>
