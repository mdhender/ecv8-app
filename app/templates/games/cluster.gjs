import { pageTitle } from 'ember-page-title';
import { LinkTo } from '@ember/routing';
import Alert from 'ec/components/ui/alert';
import GameClusterForm from 'ec/components/game-cluster-form';
import { formatDateTime } from 'ec/utils/format';

/*
 * A game's cluster: the map if it has one, and the form to generate it if it
 * does not.
 *
 * Which of the four things below a reader sees is entirely the server's answer.
 * `is_set_up` says whether the game has the seed a map is drawn from,
 * `is_active` whether it is still being played, and `options` is present only
 * when the form could actually be submitted — so the page renders what it was
 * told rather than re-deriving a rule the engine owns.
 *
 * Only a game master reaches this page at all. That is not enforced here: the
 * endpoint answers a player 403 and an unseated account 404, and the error
 * route renders both. A check here would be a second authority on a question
 * that already has one, and it would be the wrong one.
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
        <p class="mt-1 text-sm text-slate-600 dark:text-slate-300">
          These settings and the game's seed are what would have to be repeated
          to produce this map again.
        </p>
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
      {{! Active, no cluster, and no form: the only way to reach here is a game
          that has not been set up, because an active game that has been would
          have been sent the settings to generate with. }}
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

    {{else}}
      <Alert @kind="warning" @title="This game is closed">
        <p>
          An administrator has deactivated it, so it cannot be given a cluster.
          Ask them to reopen it if that was not intended.
        </p>
      </Alert>
    {{/if}}
  </div>
</template>
