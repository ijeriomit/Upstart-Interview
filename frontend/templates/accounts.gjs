import { LinkTo } from '@ember/routing';

<template>
  <div class="accounts-dashboard">
    <header class="accounts-dashboard-header">
      <div class="accounts-dashboard-shell accounts-dashboard-header-inner">
        <LinkTo
          @route="accounts.index"
          class="accounts-dashboard-brand"
        >Accounts Dashboard</LinkTo>
        <div class="accounts-dashboard-identity">
          <span>Demo user</span>
          <strong>{{@model.name}}</strong>
        </div>
      </div>
    </header>
    <main class="accounts-dashboard-shell accounts-dashboard-main">
      {{outlet}}
    </main>
  </div>
</template>
