import { pageTitle } from 'ember-page-title';
import ActivateForm from 'ec/components/activate-form';

<template>
  {{pageTitle "Activate your account"}}

  <div class="mx-auto max-w-md space-y-6">
    <div>
      <h1 class="text-2xl font-semibold">Activate your account</h1>
      <p class="mt-1 text-sm text-slate-600 dark:text-slate-300">
        Choose a password to finish setting up your account. This link works
        once and expires 48 hours after it was created.
      </p>
    </div>

    <div
      class="rounded-lg border border-slate-200 bg-white p-6 dark:border-slate-700 dark:bg-slate-900"
    >
      <ActivateForm @token={{@model.token}} />
    </div>
  </div>
</template>
