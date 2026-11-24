import { LinkTo } from '@ember/routing';
import { pageTitle } from 'ember-page-title';
import SignInForm from '../components/sign-in-form';

<template>
  {{pageTitle "Sign in"}}
  <main class="accounts-dashboard-shell accounts-dashboard-main">
    <section class="accounts-dashboard-card accounts-dashboard-auth-card">
      <h1>Sign in</h1>
      <p class="accounts-dashboard-intro">
        Try the seeded user
        <strong>alex@example.test</strong>
        with the default password
        <strong>mock-password</strong>, or sign in with an account you created.
      </p>
      <SignInForm
        @onSubmit={{@controller.signIn}}
        @isSubmitting={{@controller.accountsApi.isChangingSession}}
      />
      <p class="accounts-dashboard-intro">
        <LinkTo @route="sign-up">Create a user</LinkTo>
      </p>
    </section>
  </main>
</template>
