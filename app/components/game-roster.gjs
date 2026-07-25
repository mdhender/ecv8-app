import Component from '@glimmer/component';
import { service } from '@ember/service';
import { tracked } from '@glimmer/tracking';
import { on } from '@ember/modifier';
import { fn } from '@ember/helper';
import Alert from 'ec/components/ui/alert';
import Badge from 'ec/components/ui/badge';
import Empty from 'ec/components/ui/empty';
import Field from 'ec/components/ui/field';
import { ApiError } from 'ec/services/api';

/**
 * GameRoster is how a game master manages who is at their table.
 *
 * One rule from the server shapes the whole thing: a game master may change
 * player seats, and a game master's seat is an administrator's business. So a
 * GM row offers no controls at all — not promotion, not demotion, not
 * deactivation, and not for your own row either, since a game whose last master
 * deactivated themselves is a game nobody can run.
 *
 * The absent controls are explained in the row rather than left as a gap. A
 * control that is simply missing reads as a bug; a sentence saying who can do
 * it reads as a rule.
 *
 * People are added by email address, because a game master has no account
 * directory and should not: listing accounts is an administrator's endpoint.
 * The server answers alike for an address that belongs to nobody, to an
 * administrator, or to a deactivated account, so this form cannot tell a game
 * master which of those it was — that is the point, and the message it renders
 * is the server's.
 */
export default class GameRoster extends Component {
  @service api;
  @service router;

  @tracked email = '';
  @tracked addAsGM = false;
  @tracked status = null;
  @tracked error = null;
  @tracked fieldErrors = {};
  /** Which control is in flight, so only that one shows as busy. */
  @tracked busy = null;

  get players() {
    return this.args.players ?? [];
  }

  updateEmail = (event) => {
    this.email = event.target.value;
  };

  updateRole = (event) => {
    this.addAsGM = event.target.value === 'gm';
  };

  async perform(key, work, successMessage) {
    this.status = null;
    this.error = null;
    this.fieldErrors = {};
    this.busy = key;
    try {
      await work();
      this.status = successMessage;
      this.router.refresh('games.detail');
    } catch (error) {
      if (error instanceof ApiError) {
        this.error = error.message;
        this.fieldErrors = error.fields;
      } else {
        this.error = 'Could not reach the server. Try again.';
      }
    } finally {
      this.busy = null;
    }
  }

  add = (event) => {
    event.preventDefault();
    const email = this.email.trim();
    if (email === '') {
      return;
    }
    const asGM = this.addAsGM;
    return this.perform(
      'add',
      async () => {
        await this.api.post(`/games/${this.args.game.id}/players`, {
          email,
          is_gm: asGM,
        });
        // Only cleared on success, so a rejected address stays in the field to
        // be corrected rather than having to be typed again.
        this.email = '';
      },
      asGM ? 'Game master added.' : 'Player added.',
    );
  };

  promote = (player) =>
    this.perform(
      `promote-${player.player_id}`,
      () =>
        this.api.patch(
          `/games/${this.args.game.id}/players/${player.player_id}`,
          { is_gm: true },
        ),
      `${player.display_name} is now a game master.`,
    );

  toggleActive = (player) =>
    this.perform(
      `active-${player.player_id}`,
      () =>
        this.api.patch(
          `/games/${this.args.game.id}/players/${player.player_id}`,
          { is_active: !player.is_active },
        ),
      player.is_active ? 'Player deactivated.' : 'Player reactivated.',
    );

  <template>
    <section class="space-y-4">
      <h2 class="text-lg font-semibold">Players</h2>

      {{#if this.status}}
        <Alert @kind="success"><p>{{this.status}}</p></Alert>
      {{/if}}
      {{#if this.error}}
        <Alert @kind="error" @title="Could not update the roster">
          <p>{{this.error}}</p>
        </Alert>
      {{/if}}

      <form
        class="flex flex-wrap items-end gap-3 rounded-md border border-slate-200 p-4 dark:border-slate-700"
        {{on "submit" this.add}}
      >
        <div class="min-w-64 flex-1">
          <Field
            @name="add-player-email"
            @label="Add someone by email"
            @required={{true}}
            @hint="They need an account already; administrators create those."
            @error={{this.fieldErrors.email}}
            as |f|
          >
            <input
              id={{f.id}}
              type="email"
              required
              maxlength="254"
              autocomplete="off"
              aria-invalid={{f.invalid}}
              aria-describedby={{f.describedBy}}
              value={{this.email}}
              class="w-full rounded-md border border-slate-300 px-3 py-2 dark:border-slate-600 dark:bg-slate-800"
              {{on "input" this.updateEmail}}
            />
          </Field>
        </div>

        <div>
          <label
            for="add-player-role"
            class="block text-sm font-medium text-slate-700 dark:text-slate-200"
          >
            Join as
          </label>
          <select
            id="add-player-role"
            class="mt-1 rounded-md border border-slate-300 px-3 py-2 dark:border-slate-600 dark:bg-slate-800"
            {{on "change" this.updateRole}}
          >
            <option value="player">Player</option>
            <option value="gm">Game master</option>
          </select>
        </div>

        <button
          type="submit"
          disabled={{this.busy}}
          class="rounded-md bg-brand-600 px-4 py-2 font-medium text-white hover:bg-brand-700 disabled:opacity-60"
        >
          Add
        </button>
      </form>

      {{#if this.players.length}}
        <div class="overflow-x-auto">
          <table class="w-full text-left text-sm">
            <caption class="sr-only">
              Everyone seated at this game, and what you can change about them
            </caption>
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
              {{#each this.players as |player|}}
                <tr class="border-b border-slate-100 dark:border-slate-800">
                  <td class="py-2 pr-4">
                    <div class="font-medium">{{player.display_name}}</div>
                    <div class="text-xs text-slate-500 dark:text-slate-400">
                      {{player.email}}
                    </div>
                  </td>
                  <td class="py-2 pr-4">
                    <Badge @tone={{if player.is_gm "info" "off"}}>
                      {{if player.is_gm "Game master" "Player"}}
                    </Badge>
                  </td>
                  <td class="py-2 pr-4">
                    <Badge @tone={{if player.is_active "on" "off"}}>
                      {{if player.is_active "Active" "Inactive"}}
                    </Badge>
                  </td>
                  <td class="py-2">
                    {{#if player.is_gm}}
                      <span class="text-xs text-slate-500 dark:text-slate-400">
                        Only an administrator can change a game master's seat.
                      </span>
                    {{else}}
                      <div class="flex flex-wrap gap-2">
                        <button
                          type="button"
                          disabled={{this.busy}}
                          class="rounded-md border border-slate-300 px-3 py-1 hover:bg-slate-100 disabled:opacity-60 dark:border-slate-600 dark:hover:bg-slate-700"
                          {{on "click" (fn this.promote player)}}
                        >
                          Make game master
                        </button>
                        <button
                          type="button"
                          disabled={{this.busy}}
                          class="rounded-md border border-slate-300 px-3 py-1 hover:bg-slate-100 disabled:opacity-60 dark:border-slate-600 dark:hover:bg-slate-700"
                          {{on "click" (fn this.toggleActive player)}}
                        >
                          {{if player.is_active "Deactivate" "Reactivate"}}
                        </button>
                      </div>
                    {{/if}}
                  </td>
                </tr>
              {{/each}}
            </tbody>
          </table>
        </div>

        <p class="text-xs text-slate-500 dark:text-slate-400">
          Promoting someone cannot be undone here, and nobody is ever removed —
          deactivating a seat keeps the game's history intact. An administrator
          can undo either.
        </p>
      {{else}}
        <Empty @title="Nobody is seated at this game yet">
          Add someone by their email address above.
        </Empty>
      {{/if}}
    </section>
  </template>
}
