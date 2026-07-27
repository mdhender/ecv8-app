import { pageTitle } from 'ember-page-title';
import { LinkTo } from '@ember/routing';
import Alert from 'ec/components/ui/alert';
import GameClusterForm from 'ec/components/game-cluster-form';
import { formatDateTime } from 'ec/utils/format';

/*
 * A game's cluster, for anybody seated at the game: the map if it has one, the
 * form to generate it for the game master who can, and an explanation of what
 * is missing for everyone else.
 *
 * **The map is the same page for a player and for a game master**, because it
 * is the same map. Space being a known shape is what makes a course worth
 * plotting, and unlike the seed a coordinate list says nothing about the
 * future. A second route rendering the same coordinates at a second URL would
 * be two pages to keep in step for no difference a reader could see.
 *
 * What differs is what surrounds it, and every part of that is the server's
 * answer rather than this page's reasoning. `options` is present only for a
 * caller who could submit the form, so a player is not shown one and there is
 * nothing here that decides to hide it. `is_gm` is what remains, and it is used
 * for wording alone — "you have not generated this yet" and "it has not been
 * generated yet" are one fact told to two readers.
 *
 * There is no guard here and there must not be one. A player who is not at the
 * table is answered 404 by the endpoint and the error route renders it; a check
 * here would be a second authority on a question that already has one.
 */

/** Reports display a stellium as (x, y, z), so the map does too. */
function coordinates(stellium) {
  return `(${stellium.x}, ${stellium.y}, ${stellium.z})`;
}

<template>
  {{pageTitle "Cluster"}}

  <div class="space-y-6">
    <div>
      <LinkTo
        @route="games.detail"
        @model={{@model.game_id}}
        class="text-sm text-brand-700 underline dark:text-brand-200"
      >
        Back to
        {{@model.game_name}}
      </LinkTo>
      <h1 class="mt-2 text-2xl font-semibold">Cluster</h1>
    </div>

    {{#if @model.cluster}}
      <section
        class="rounded-md border border-slate-200 p-4 dark:border-slate-700"
      >
        <h2 class="text-lg font-semibold">How this map was made</h2>
        {{! The seed is the game master's, so only they are told that these
            settings and it are together the whole recipe. A player is told
            what the numbers mean for them: how much space there is. }}
        {{#if @model.is_gm}}
          <p class="mt-1 text-sm text-slate-600 dark:text-slate-300">
            These settings and the game's seed are what would have to be
            repeated to produce this map again.
          </p>
        {{else}}
          <p class="mt-1 text-sm text-slate-600 dark:text-slate-300">
            This is the whole of explorable space in this game.
          </p>
        {{/if}}
        <dl class="mt-3 grid gap-3 sm:grid-cols-4">
          <div>
            <dt
              class="text-sm text-slate-600 dark:text-slate-300"
            >Generator</dt>
            <dd class="font-medium">{{@model.cluster.generator}}</dd>
          </div>
          <div>
            <dt
              class="text-sm text-slate-600 dark:text-slate-300"
            >Stelliums</dt>
            <dd class="font-medium">{{@model.cluster.stellium_count}}</dd>
          </div>
          <div>
            <dt class="text-sm text-slate-600 dark:text-slate-300">Radius</dt>
            <dd class="font-medium">{{@model.cluster.radius}}</dd>
          </div>
          <div>
            <dt
              class="text-sm text-slate-600 dark:text-slate-300"
            >Generated</dt>
            <dd class="font-medium">
              {{formatDateTime @model.cluster.created_at}}
            </dd>
          </div>
        </dl>
      </section>

      <section class="space-y-3">
        <h2 class="text-lg font-semibold">Stelliums</h2>
        <div class="overflow-x-auto">
          <table class="w-full text-left text-sm">
            <caption class="sr-only">
              Every stellium in this cluster, with its identifier and map
              coordinates
            </caption>
            <thead
              class="border-b border-slate-200 text-slate-600 dark:border-slate-700 dark:text-slate-300"
            >
              <tr>
                <th scope="col" class="py-2 pr-4">ID</th>
                <th scope="col" class="py-2 pr-4">Coordinates</th>
                <th scope="col" class="py-2 pr-4">X</th>
                <th scope="col" class="py-2 pr-4">Y</th>
                <th scope="col" class="py-2">Z</th>
              </tr>
            </thead>
            <tbody>
              {{#each @model.cluster.stelliums as |stellium|}}
                <tr class="border-b border-slate-100 dark:border-slate-800">
                  <td class="py-2 pr-4 font-mono">{{stellium.id}}</td>
                  <td class="py-2 pr-4 font-mono">{{coordinates stellium}}</td>
                  <td class="py-2 pr-4 font-mono">{{stellium.x}}</td>
                  <td class="py-2 pr-4 font-mono">{{stellium.y}}</td>
                  <td class="py-2 font-mono">{{stellium.z}}</td>
                </tr>
              {{/each}}
            </tbody>
          </table>
        </div>
      </section>

    {{else if @model.options}}
      <GameClusterForm @gameId={{@model.game_id}} @options={{@model.options}} />

    {{else if @model.is_active}}
      {{! No map, and no form either. For a game master that can only mean the
          game has not been set up, since an active game that has been would
          have been sent the settings to generate with. For a player it means
          whichever of the two the server said. }}
      {{#if @model.is_gm}}
        <Alert @kind="info" @title="This game has not been set up yet">
          <p>
            A cluster is drawn from the game's seed, so there is nothing to
            generate from until the game has been started.
            <LinkTo
              @route="games.detail"
              @model={{@model.game_id}}
              class="underline"
            >
              Set
              {{@model.game_name}}
              up
            </LinkTo>
            first, then come back.
          </p>
        </Alert>
      {{else if @model.is_set_up}}
        <Alert @kind="info" @title="This game has no map yet">
          <p>
            The game master has started
            {{@model.game_name}}
            but has not generated its cluster. Check back later — the map will
            appear here once they have.
          </p>
        </Alert>
      {{else}}
        <Alert @kind="info" @title="This game is being set up">
          <p>
            The game master has not started
            {{@model.game_name}}
            yet, and a cluster is drawn from the seed that starting it writes.
            Check back later.
          </p>
        </Alert>
      {{/if}}

    {{else}}
      <Alert @kind="warning" @title="This game is closed">
        <p>
          An administrator has deactivated it, so it has no map and cannot be
          given one.
          {{#if @model.is_gm}}
            Ask them to reopen it if that was not intended.
          {{/if}}
        </p>
      </Alert>
    {{/if}}
  </div>
</template>
