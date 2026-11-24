import { LinkTo } from '@ember/routing';
import { pageTitle } from 'ember-page-title';
import SignInForm from '../components/sign-in-form';
import { DEMO_EMAIL, DEMO_PASSWORD } from '../services/demo-access';

<template>
  {{pageTitle "Sign in"}}
  <main
    class="accounts-dashboard accounts-dashboard-shell accounts-dashboard-main"
  >
    <section class="accounts-dashboard-card accounts-dashboard-auth-card">
      <h1>Sign in</h1>
      <p class="accounts-dashboard-intro">
        Try the demo with
        <strong>{{DEMO_EMAIL}}</strong>
        and password
        <strong>{{DEMO_PASSWORD}}</strong>.
      </p>
      <SignInForm
        @onSubmit={{@controller.signIn}}
        @isSubmitting={{@controller.isSubmitting}}
      />
      <p class="accounts-dashboard-intro">
        <LinkTo @route="sign-up">Create a demo user</LinkTo>
      </p>
    </section>
  </main>
</template>
