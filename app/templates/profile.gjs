import { pageTitle } from 'ember-page-title';
import ProfileForm from 'ec/components/profile-form';
import PasswordForm from 'ec/components/password-form';

<template>
  {{pageTitle "Profile"}}

  <div class="mx-auto max-w-2xl space-y-8">
    <div>
      <h1 class="text-2xl font-semibold">Profile</h1>
      <p class="mt-1 text-sm text-slate-600 dark:text-slate-300">
        Signed in as
        {{@model.account.email}}. Only an administrator can change your email
        address or role.
      </p>
    </div>

    <section
      class="space-y-4 rounded-lg border border-slate-200 bg-white p-6 dark:border-slate-700 dark:bg-slate-900"
    >
      <h2 class="text-lg font-semibold">Details</h2>
      <ProfileForm @account={{@model.account}} />
    </section>

    <section
      class="space-y-4 rounded-lg border border-slate-200 bg-white p-6 dark:border-slate-700 dark:bg-slate-900"
    >
      <h2 class="text-lg font-semibold">Password</h2>
      <PasswordForm />
    </section>
  </div>
</template>
