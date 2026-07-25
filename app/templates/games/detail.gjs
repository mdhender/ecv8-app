import { pageTitle } from 'ember-page-title';
import { LinkTo } from '@ember/routing';
import Alert from 'ec/components/ui/alert';
import Badge from 'ec/components/ui/badge';
import GameRoster from 'ec/components/game-roster';
import GameSetupForm from 'ec/components/game-setup-form';
import { formatDateTime } from 'ec/utils/format';

/*
 * One game, in whichever of its three states it is in: set up, waiting for its
 * game master, or waiting for a player's game master to get to it.
 *
 * `state` is null until the game has been set up, and which of the last two a
 * reader sees is decided by `is_gm` — both of which the server sends, because
 * both are its decision. The client only chooses the wording.
 */

/** Turn 0 is setup rather than a played turn, and reads oddly unlabelled. */
function turnLabel(turn) {
  return turn === 0 ? 'Setup (turn 0)' : `Turn ${turn}`;
}

<template>
  {{pageTitle @model.game.name}}

  <div class="space-y-6">
    <div>
      <LinkTo
        @route="games.index"
        class="text-sm text-brand-700 underline dark:text-brand-200"
      >
        Back to games
      </LinkTo>
      <div class="mt-2 flex flex-wrap items-center gap-3">
        <h1 class="text-2xl font-semibold">{{@model.game.name}}</h1>
        <Badge @tone={{if @model.game.is_gm "info" "off"}}>
          {{if @model.game.is_gm "Game master" "Player"}}
        </Badge>
        {{#unless @model.game.is_active}}
          <Badge @tone="off">Closed</Badge>
        {{/unless}}
      </div>
    </div>

    {{#unless @model.game.is_active}}
      <Alert @kind="warning" @title="This game is closed">
        <p>
          An administrator has deactivated it. It stays here so you can see the
          game you played, but it cannot be started or continued.
        </p>
      </Alert>
    {{/unless}}

    {{#if @model.game.state}}
      <section
        class="rounded-md border border-slate-200 p-4 dark:border-slate-700"
      >
        <h2 class="text-lg font-semibold">Status</h2>
        <dl class="mt-3 grid gap-3 sm:grid-cols-3">
          <div>
            <dt class="text-sm text-slate-600 dark:text-slate-300">Turn</dt>
            <dd class="font-medium">{{turnLabel @model.game.state.turn}}</dd>
          </div>
          <div>
            <dt class="text-sm text-slate-600 dark:text-slate-300">
              Started
            </dt>
            <dd class="font-medium">
              {{formatDateTime @model.game.state.created_at}}
            </dd>
          </div>
          <div>
            <dt class="text-sm text-slate-600 dark:text-slate-300">Seed</dt>
            {{! The seed is shown so a game master can record it: it is what
                makes a turn replayable, and it can never be changed. }}
            <dd class="font-mono text-sm break-all">
              {{@model.game.state.seed.hi}}
              /
              {{@model.game.state.seed.lo}}
            </dd>
          </div>
        </dl>
      </section>
    {{else if @model.game.is_gm}}
      <GameSetupForm @game={{@model.game}} />
    {{else}}
      <Alert @kind="info" @title="This game is being set up">
        <p>
          The game master has not started it yet. Check back later — it will
          appear here once they have.
        </p>
      </Alert>
    {{/if}}

    {{! The roster is the game master's, and is loaded only for one. It sits
        below the setup form so that starting the game — the thing a new game
        needs first — is what the page opens on. }}
    {{#if @model.game.is_gm}}
      <GameRoster @game={{@model.game}} @players={{@model.players}} />
    {{/if}}
  </div>
</template>
