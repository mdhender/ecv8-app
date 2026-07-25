import { LinkTo } from '@ember/routing';
import Badge from 'ec/components/ui/badge';
import Empty from 'ec/components/ui/empty';
import Pager from 'ec/components/ui/pager';
import ListFilters from 'ec/components/admin/list-filters';
import InviteForm from 'ec/components/admin/invite-form';

function currentQuery(controller) {
  return {
    q: controller.q,
    role: controller.role,
    active: controller.active,
  };
}

<template>
  <div class="space-y-6">
    <InviteForm />

    <ListFilters
      @route="admin.accounts.index"
      @q={{@controller.q}}
      @role={{@controller.role}}
      @active={{@controller.active}}
      @showRole={{true}}
      @placeholder="Email or display name"
    />

    {{#if @model.accounts.length}}
      <div class="overflow-x-auto">
        <table class="w-full text-left text-sm">
          <caption class="sr-only">Accounts</caption>
          <thead
            class="border-b border-slate-200 text-slate-600 dark:border-slate-700 dark:text-slate-300"
          >
            <tr>
              <th scope="col" class="py-2 pr-4">Account</th>
              <th scope="col" class="py-2 pr-4">Role</th>
              <th scope="col" class="py-2 pr-4">Status</th>
              <th scope="col" class="py-2 pr-4">Sessions</th>
              <th scope="col" class="py-2"><span
                  class="sr-only"
                >Manage</span></th>
            </tr>
          </thead>
          <tbody>
            {{#each @model.accounts as |account|}}
              <tr class="border-b border-slate-100 dark:border-slate-800">
                <td class="py-2 pr-4">
                  <div class="font-medium">{{account.display_name}}</div>
                  <div class="text-xs text-slate-500 dark:text-slate-400">
                    {{account.email}}
                  </div>
                </td>
                <td class="py-2 pr-4">
                  <Badge @tone="info">{{account.role}}</Badge>
                </td>
                <td class="py-2 pr-4">
                  <div class="flex flex-wrap gap-1">
                    <Badge @tone={{if account.is_active "on" "off"}}>
                      {{if account.is_active "Active" "Deactivated"}}
                    </Badge>
                    {{#unless account.activated}}
                      <Badge @tone="warn">Not activated</Badge>
                    {{/unless}}
                    {{#if account.activation_pending}}
                      <Badge @tone="warn">Link outstanding</Badge>
                    {{/if}}
                  </div>
                </td>
                <td class="py-2 pr-4">{{account.active_sessions}}</td>
                <td class="py-2">
                  <LinkTo
                    @route="admin.accounts.detail"
                    @model={{account.id}}
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
        @route="admin.accounts.index"
        @query={{currentQuery @controller}}
      />
    {{else}}
      <Empty @title="No accounts match these filters">
        Adjust the search above, or invite an account.
      </Empty>
    {{/if}}
  </div>
</template>
