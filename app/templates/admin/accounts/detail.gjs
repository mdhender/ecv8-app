import { pageTitle } from 'ember-page-title';
import { LinkTo } from '@ember/routing';
import AccountForm from 'ec/components/admin/account-form';

<template>
  {{pageTitle @model.account.email}}

  <div class="space-y-6">
    <div>
      <LinkTo
        @route="admin.accounts"
        class="text-sm text-brand-700 underline dark:text-brand-200"
      >
        Back to accounts
      </LinkTo>
      <h2
        class="mt-2 text-xl font-semibold"
      >{{@model.account.display_name}}</h2>
      <p class="text-sm text-slate-600 dark:text-slate-300">
        {{@model.account.email}}
      </p>
    </div>

    <AccountForm @account={{@model.account}} />
  </div>
</template>
