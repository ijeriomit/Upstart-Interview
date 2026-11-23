import { LinkTo } from '@ember/routing';

<template>
  <div class="fieldwork">
    <header class="fieldwork-header">
      <div class="fieldwork-shell fieldwork-header-inner">
        <LinkTo
          @route="accounts.index"
          class="fieldwork-brand"
        >Fieldwork</LinkTo>
        <div class="fieldwork-identity">
          <span>Demo user</span>
          <strong>{{@model.name}}</strong>
        </div>
      </div>
    </header>
    <main class="fieldwork-shell fieldwork-main">
      {{outlet}}
    </main>
  </div>
</template>
