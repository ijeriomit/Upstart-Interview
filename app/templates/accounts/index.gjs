import { LinkTo } from '@ember/routing';
import { pageTitle } from 'ember-page-title';
import usd from '../../helpers/usd';

<template>
  {{pageTitle "Accounts"}}
  <h1>Accounts</h1>
  <p class="fieldwork-intro">Review your balances and account activity.</p>
  <ul class="fieldwork-account-grid">
    {{#each @model as |account|}}
      <li class="fieldwork-card">
        <h2>{{account.name}}</h2>
        <p class="fieldwork-label">Current balance</p>
        <p class="fieldwork-amount">{{usd account.balance}}</p>
        <LinkTo
          @route="accounts.show"
          @model={{account.id}}
          class="fieldwork-card-link"
        >
          View
          {{account.name}}
        </LinkTo>
      </li>
    {{else}}
      <li class="fieldwork-card">You have no accounts yet.</li>
    {{/each}}
  </ul>
</template>
