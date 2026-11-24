import { LinkTo } from '@ember/routing';
import { pageTitle } from 'ember-page-title';
import SignUpForm from '../components/sign-up-form';

<template>
  {{pageTitle "Sign up"}}
  <main
    class="accounts-dashboard accounts-dashboard-shell accounts-dashboard-main"
  >
    <section class="accounts-dashboard-card accounts-dashboard-auth-card">
      <h1>Welcome to UpstartInterview</h1>
      <p class="accounts-dashboard-intro">
        Create a demo user and set up your opening accounts. Use a made-up
        password for this preview.
      </p>
      <SignUpForm @onSubmit={{@controller.register}} />
      <p class="accounts-dashboard-intro"><LinkTo @route="sign-in">Back to sign
          in</LinkTo></p>
    </section>
  </main>
</template>
