import Component from '@glimmer/component';
import { service } from '@ember/service';
import { tracked } from '@glimmer/tracking';
import { on } from '@ember/modifier';
import { fn } from '@ember/helper';
import Alert from 'ec/components/ui/alert';
import Badge from 'ec/components/ui/badge';
import Empty from 'ec/components/ui/empty';
import { ApiError } from 'ec/services/api';

/**
 * MembershipEditor manages who plays a game and who runs it.
 *
 * Game-master status is per game, not an application role, so the same account
 * can run one game and play in another. Only user accounts appear in the picker
 * because the database refuses to put an administrator in a game at all.
 *
 * Memberships are deactivated rather than removed, which keeps a game's roster
 * history intact.
 */
export default class MembershipEditor extends Component {
  @service api;
  @service router;

  @tracked selectedAccountId = '';
  @tracked status = null;
  @tracked error = null;
  @tracked busy = null;

  /** Accounts that are not already members, so the picker offers only new ones. */
  get available() {
    const existing = new Set(
      this.args.memberships.map((membership) => membership.account_id),
    );
    return this.args.candidates.filter((account) => !existing.has(account.id));
  }

  get hasAvailable() {
    return this.available.length > 0;
  }

  updateSelection = (event) => {
    this.selectedAccountId = event.target.value;
  };

  async save(key, accountId, body, successMessage) {
    this.status = null;
    this.error = null;
    this.busy = key;
    try {
      await this.api.put(
        `/admin/games/${this.args.game.id}/memberships/${accountId}`,
        body,
      );
      this.status = successMessage;
      this.router.refresh('admin.games.detail');
    } catch (error) {
      this.error =
        error instanceof ApiError
          ? error.message
          : 'Could not reach the server. Try again.';
    } finally {
      this.busy = null;
    }
  }

  add = (event) => {
    event.preventDefault();
    if (!this.selectedAccountId) {
      return;
    }
    const accountId = this.selectedAccountId;
    this.selectedAccountId = '';
    return this.save(
      'add',
      accountId,
      { is_gm: false, is_active: true },
      'Player added.',
    );
  };

  toggleGm = (membership) =>
    this.save(
      `gm-${membership.account_id}`,
      membership.account_id,
      { is_gm: !membership.is_gm, is_active: membership.is_active },
      membership.is_gm ? 'Game-master status removed.' : 'Game master set.',
    );

  toggleActive = (membership) =>
    this.save(
      `active-${membership.account_id}`,
      membership.account_id,
      { is_gm: membership.is_gm, is_active: !membership.is_active },
      membership.is_active
        ? 'Membership deactivated.'
        : 'Membership reactivated.',
    );

  <template>
    <section class="space-y-4">
      <h3 class="text-lg font-semibold">Members</h3>

      {{#if this.status}}
        <Alert @kind="success"><p>{{this.status}}</p></Alert>
      {{/if}}
      {{#if this.error}}
        <Alert @kind="error" @title="Could not update membership">
          <p>{{this.error}}</p>
        </Alert>
      {{/if}}

      <form class="flex flex-wrap items-end gap-3" {{on "submit" this.add}}>
        <div class="min-w-64 flex-1">
          <label
            for="add-member"
            class="block text-sm font-medium text-slate-700 dark:text-slate-200"
          >
            Add a player
          </label>
          <select
            id="add-member"
            disabled={{unless this.hasAvailable true}}
            class="mt-1 w-full rounded-md border border-slate-300 px-3 py-2 dark:border-slate-600 dark:bg-slate-800"
            {{on "change" this.updateSelection}}
          >
            <option value="">Choose an account…</option>
            {{#each this.available as |account|}}
              <option value={{account.id}}>
                {{account.display_name}}
                ({{account.email}})
              </option>
            {{/each}}
          </select>
          {{#unless this.hasAvailable}}
            <p class="mt-1 text-xs text-slate-500 dark:text-slate-400">
              Every active user account is already a member.
            </p>
          {{/unless}}
        </div>

        <button
          type="submit"
          disabled={{this.busy}}
          class="rounded-md bg-brand-600 px-4 py-2 font-medium text-white hover:bg-brand-700 disabled:opacity-60"
        >
          Add
        </button>
      </form>

      {{#if @memberships.length}}
        <div class="overflow-x-auto">
          <table class="w-full text-left text-sm">
            <thead
              class="border-b border-slate-200 text-slate-600 dark:border-slate-700 dark:text-slate-300"
            >
              <tr>
                <th scope="col" class="py-2 pr-4">Account</th>
                <th scope="col" class="py-2 pr-4">Role in game</th>
                <th scope="col" class="py-2 pr-4">Status</th>
                <th scope="col" class="py-2">Actions</th>
              </tr>
            </thead>
            <tbody>
              {{#each @memberships as |membership|}}
                <tr class="border-b border-slate-100 dark:border-slate-800">
                  <td class="py-2 pr-4">
                    <div class="font-medium">{{membership.display_name}}</div>
                    <div class="text-xs text-slate-500 dark:text-slate-400">
                      {{membership.email}}
                    </div>
                  </td>
                  <td class="py-2 pr-4">
                    <Badge @tone={{if membership.is_gm "info" "off"}}>
                      {{if membership.is_gm "Game master" "Player"}}
                    </Badge>
                  </td>
                  <td class="py-2 pr-4">
                    <Badge @tone={{if membership.is_active "on" "off"}}>
                      {{if membership.is_active "Active" "Inactive"}}
                    </Badge>
                  </td>
                  <td class="py-2">
                    <div class="flex flex-wrap gap-2">
                      <button
                        type="button"
                        disabled={{this.busy}}
                        class="rounded-md border border-slate-300 px-2 py-1 text-xs hover:bg-slate-100 disabled:opacity-60 dark:border-slate-600 dark:hover:bg-slate-700"
                        {{on "click" (fn this.toggleGm membership)}}
                      >
                        {{if membership.is_gm "Make player" "Make game master"}}
                      </button>
                      <button
                        type="button"
                        disabled={{this.busy}}
                        class="rounded-md border border-slate-300 px-2 py-1 text-xs hover:bg-slate-100 disabled:opacity-60 dark:border-slate-600 dark:hover:bg-slate-700"
                        {{on "click" (fn this.toggleActive membership)}}
                      >
                        {{if membership.is_active "Deactivate" "Reactivate"}}
                      </button>
                    </div>
                  </td>
                </tr>
              {{/each}}
            </tbody>
          </table>
        </div>
      {{else}}
        <Empty @title="No members yet">
          Add an active user account above to put them in this game.
        </Empty>
      {{/if}}
    </section>
  </template>
}
