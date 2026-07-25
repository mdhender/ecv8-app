import { pageTitle } from 'ember-page-title';
import { LinkTo } from '@ember/routing';
import Badge from 'ec/components/ui/badge';
import Empty from 'ec/components/ui/empty';
import { formatDateTime } from 'ec/utils/format';

<template>
  {{pageTitle "Dashboard"}}

  <div class="space-y-6">
    <h1 class="text-2xl font-semibold">Dashboard</h1>

    <section class="space-y-4">
      <h2 class="text-lg font-semibold">Your games</h2>

      {{#if @model.memberships.length}}
        <ul class="grid gap-4 sm:grid-cols-2">
          {{#each @model.memberships as |membership|}}
            <li
              class="rounded-lg border border-slate-200 bg-white p-4 dark:border-slate-700 dark:bg-slate-900"
            >
              <div class="flex items-start justify-between gap-3">
                <h3 class="font-medium">{{membership.game_name}}</h3>
                <Badge @tone={{if membership.is_gm "info" "off"}}>
                  {{if membership.is_gm "Game master" "Player"}}
                </Badge>
              </div>
              <p class="mt-2 text-sm text-slate-600 dark:text-slate-300">
                Joined
                {{formatDateTime membership.created_at}}
              </p>
            </li>
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
