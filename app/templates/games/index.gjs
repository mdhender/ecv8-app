import { pageTitle } from 'ember-page-title';
import Empty from 'ec/components/ui/empty';
import GameCard from 'ec/components/game-card';

<template>
  {{pageTitle "Games"}}

  <div class="space-y-6">
    <h1 class="text-2xl font-semibold">Games</h1>

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
  </div>
</template>
