import { LinkTo } from '@ember/routing';
import Badge from 'ec/components/ui/badge';
import { formatDateTime } from 'ec/utils/format';

/**
 * GameCard is one of your games in a list of them.
 *
 * The game's name is the link rather than a separate "open" control beside it,
 * so what a screen reader announces as the target is the game itself instead of
 * a verb that has to be paired back up with a heading to mean anything.
 *
 * It takes a membership — the shape `GET /me/games` returns — because that is
 * what both lists of games have in hand. `game_id` is the seat's game, which is
 * the id the detail route wants.
 */
<template>
  <li
    class="rounded-lg border border-slate-200 bg-white p-4 dark:border-slate-700 dark:bg-slate-900"
  >
    <div class="flex items-start justify-between gap-3">
      <h3 class="font-medium">
        <LinkTo
          @route="games.detail"
          @model={{@membership.game_id}}
          class="text-brand-700 underline dark:text-brand-200"
        >
          {{@membership.game_name}}
        </LinkTo>
      </h3>
      <Badge @tone={{if @membership.is_gm "info" "off"}}>
        {{if @membership.is_gm "Game master" "Player"}}
      </Badge>
    </div>
    <p class="mt-2 text-sm text-slate-600 dark:text-slate-300">
      Joined
      {{formatDateTime @membership.created_at}}
    </p>
  </li>
</template>
