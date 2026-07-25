import { pageTitle } from 'ember-page-title';
import LoginForm from 'ec/components/login-form';

<template>
  {{pageTitle "Sign in"}}

  <div class="mx-auto max-w-md space-y-6">
    <div>
      <h1 class="text-2xl font-semibold">Sign in</h1>
      <p class="mt-1 text-sm text-slate-600 dark:text-slate-300">
        Accounts are created by an administrator. If you were sent an activation
        link, use that link instead.
      </p>
    </div>

    <div
      class="rounded-lg border border-slate-200 bg-white p-6 dark:border-slate-700 dark:bg-slate-900"
    >
      <LoginForm />
    </div>
  </div>
</template>
