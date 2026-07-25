import { pageTitle } from 'ember-page-title';
import { LinkTo } from '@ember/routing';
import ActivationLinkBanner from 'ec/components/admin/activation-link-banner';

<template>
  {{pageTitle "Administration"}}

  <div class="space-y-6">
    <h1 class="text-2xl font-semibold">Administration</h1>

    <nav
      class="flex gap-2 border-b border-slate-200 dark:border-slate-700"
      aria-label="Administration sections"
    >
      <LinkTo
        @route="admin.accounts"
        class="border-b-2 border-transparent px-3 py-2 text-sm hover:border-brand-300"
        @activeClass="border-brand-600 font-medium text-brand-700 dark:text-brand-200"
      >
        Accounts
      </LinkTo>
      <LinkTo
        @route="admin.games"
        class="border-b-2 border-transparent px-3 py-2 text-sm hover:border-brand-300"
        @activeClass="border-brand-600 font-medium text-brand-700 dark:text-brand-200"
      >
        Games
      </LinkTo>
    </nav>

    <ActivationLinkBanner />

    {{outlet}}
  </div>
</template>
