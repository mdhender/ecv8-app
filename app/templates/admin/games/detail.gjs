import { pageTitle } from 'ember-page-title';
import { LinkTo } from '@ember/routing';
import GameForm from 'ec/components/admin/game-form';
import MembershipEditor from 'ec/components/admin/membership-editor';

<template>
  {{pageTitle @model.game.name}}

  <div class="space-y-8">
    <div>
      <LinkTo
        @route="admin.games"
        class="text-sm text-brand-700 underline dark:text-brand-200"
      >
        Back to games
      </LinkTo>
      <h2 class="mt-2 text-xl font-semibold">{{@model.game.name}}</h2>
    </div>

    <GameForm @game={{@model.game}} />

    <MembershipEditor
      @game={{@model.game}}
      @memberships={{@model.memberships}}
      @candidates={{@model.candidates}}
    />
  </div>
</template>
