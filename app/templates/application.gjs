import { pageTitle } from 'ember-page-title';
import AppNav from 'ec/components/app-nav';
import ImpersonationBanner from 'ec/components/impersonation-banner';

<template>
  {{pageTitle "ECV8"}}

  <div
    class="min-h-screen bg-slate-50 text-slate-900 dark:bg-slate-950 dark:text-slate-100"
  >
    <a
      href="#main"
      class="sr-only focus:not-sr-only focus:absolute focus:m-2 focus:rounded-md focus:bg-white focus:px-3 focus:py-2 focus:text-brand-700"
    >
      Skip to main content
    </a>

    <AppNav />
    <ImpersonationBanner />

    <main id="main" tabindex="-1" class="mx-auto max-w-6xl px-4 py-8">
      {{outlet}}
    </main>
  </div>
</template>
