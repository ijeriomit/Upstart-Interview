import { LinkTo } from '@ember/routing';
import { pageTitle } from 'ember-page-title';
import usd from '../helpers/usd';

<template>
  {{pageTitle "Demo accounts"}}
  <main
    class="accounts-dashboard accounts-dashboard-shell accounts-dashboard-main"
  >
    <LinkTo @route="sign-in" class="accounts-dashboard-back-link">Back to sign
      in</LinkTo>
    <h1>Welcome, {{@model.name}}</h1>
    <p class="accounts-dashboard-intro">Demo accounts and opening balances</p>
    <ul class="accounts-dashboard-account-grid">
      {{#each @model.accounts as |account|}}
        <li class="accounts-dashboard-card" data-test-demo-account>
          <h2>{{account.name}}</h2>
          <p class="accounts-dashboard-account-type">{{account.accountType}}</p>
          <p class="accounts-dashboard-amount">{{usd account.balance}}</p>
        </li>
      {{/each}}
    </ul>
  </main>
</template>
