import { LinkTo } from '@ember/routing';
import Badge from 'ec/components/ui/badge';
import Empty from 'ec/components/ui/empty';
import Pager from 'ec/components/ui/pager';
import ListFilters from 'ec/components/admin/list-filters';
import CreateGameForm from 'ec/components/admin/create-game-form';

function currentQuery(controller) {
  return { q: controller.q, active: controller.active };
}

<template>
  <div class="space-y-6">
    <CreateGameForm />

    <ListFilters
      @route="admin.games.index"
      @q={{@controller.q}}
      @active={{@controller.active}}
      @placeholder="Game name"
    />

    {{#if @model.games.length}}
      <div class="overflow-x-auto">
        <table class="w-full text-left text-sm">
          <caption class="sr-only">Games</caption>
          <thead
            class="border-b border-slate-200 text-slate-600 dark:border-slate-700 dark:text-slate-300"
          >
            <tr>
              <th scope="col" class="py-2 pr-4">Name</th>
              <th scope="col" class="py-2 pr-4">Status</th>
              <th scope="col" class="py-2"><span
                  class="sr-only"
                >Manage</span></th>
            </tr>
          </thead>
          <tbody>
            {{#each @model.games as |game|}}
              <tr class="border-b border-slate-100 dark:border-slate-800">
                <td class="py-2 pr-4 font-medium">{{game.name}}</td>
                <td class="py-2 pr-4">
                  <Badge @tone={{if game.is_active "on" "off"}}>
                    {{if game.is_active "Active" "Deactivated"}}
                  </Badge>
                </td>
                <td class="py-2">
                  <LinkTo
                    @route="admin.games.detail"
                    @model={{game.id}}
                    class="text-brand-700 underline dark:text-brand-200"
                  >
                    Manage
                  </LinkTo>
                </td>
              </tr>
            {{/each}}
          </tbody>
        </table>
      </div>

      <Pager
        @meta={{@model.meta}}
        @route="admin.games.index"
        @query={{currentQuery @controller}}
      />
    {{else}}
      <Empty @title="No games match these filters">
        Adjust the search above, or create a game.
      </Empty>
    {{/if}}
  </div>
</template>
