import { LinkTo } from '@ember/routing';
import { pageTitle } from 'ember-page-title';
import Menu from '../components/menu';

<template>
  {{pageTitle "Accounts Dashboard"}}

  <div class="accounts-dashboard">
    <header class="accounts-dashboard-header">
      <div class="accounts-dashboard-shell accounts-dashboard-header-inner">
        <LinkTo @route="index" class="accounts-dashboard-brand">Accounts
          Dashboard</LinkTo>
        <Menu />
      </div>
    </header>
    {{outlet}}
  </div>
</template>
