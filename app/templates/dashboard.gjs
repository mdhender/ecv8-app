import { pageTitle } from 'ember-page-title';
import { LinkTo } from '@ember/routing';
import Empty from 'ec/components/ui/empty';
import GameCard from 'ec/components/game-card';

<template>
  {{pageTitle "Dashboard"}}

  <div class="space-y-6">
    <h1 class="text-2xl font-semibold">Dashboard</h1>

    <section class="space-y-4">
      <div class="flex flex-wrap items-baseline justify-between gap-3">
        <h2 class="text-lg font-semibold">Your games</h2>
        <LinkTo
          @route="games"
          class="text-sm text-brand-700 underline dark:text-brand-200"
        >
          All games
        </LinkTo>
      </div>

      {{#if @model.memberships.length}}
        <ul class="grid gap-4 sm:grid-cols-2">
          {{#each @model.memberships as |membership|}}
            <GameCard @membership={{membership}} />
          {{/each}}
        </ul>
      {{else}}
        <Empty @title="You are not in any games yet">
          An administrator adds accounts to games. Once you are added, the game
          appears here.
        </Empty>
      {{/if}}
    </section>

    <p class="text-sm text-slate-600 dark:text-slate-300">
      Manage your name, time zone, and password on your
      <LinkTo
        @route="profile"
        class="text-brand-700 underline dark:text-brand-200"
      >
        profile
      </LinkTo>.
    </p>
  </div>
</template>
