import Component from '@glimmer/component';
import { service } from '@ember/service';
import { tracked } from '@glimmer/tracking';
import { on } from '@ember/modifier';
import Alert from 'ec/components/ui/alert';
import Field from 'ec/components/ui/field';
import Badge from 'ec/components/ui/badge';
import { ApiError } from 'ec/services/api';

/**
 * GameForm renames a game and toggles whether it is active.
 *
 * Games are never deleted. Deactivating one hides it from players while leaving
 * its memberships and history intact, which is what "delete" means here.
 */
export default class GameForm extends Component {
  @service api;
  @service router;

  // Starts undefined and reads through to the loaded game until edited, so the
  // refresh after a save shows the server's version.
  @tracked nameEdit;

  get name() {
    return this.nameEdit ?? this.args.game.name;
  }
  @tracked status = null;
  @tracked error = null;
  @tracked fieldErrors = {};
  @tracked busy = null;

  /** True while the save button specifically is the action in flight. */
  get isSaving() {
    return this.busy === 'save';
  }

  get game() {
    return this.args.game;
  }

  updateName = (event) => {
    this.nameEdit = event.target.value;
  };

  async perform(name, work, successMessage) {
    this.status = null;
    this.error = null;
    this.fieldErrors = {};
    this.busy = name;
    try {
      await work();
      this.status = successMessage;
      this.router.refresh('admin.games.detail');
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

  save = (event) => {
    event.preventDefault();
    return this.perform(
      'save',
      () => this.api.patch(`/admin/games/${this.game.id}`, { name: this.name }),
      'Game saved.',
    );
  };

  toggleActive = () => {
    const next = !this.game.is_active;
    return this.perform(
      'active',
      () => this.api.patch(`/admin/games/${this.game.id}`, { is_active: next }),
      next ? 'Game reactivated.' : 'Game deactivated.',
    );
  };

  <template>
    <div class="space-y-4">
      {{#if this.status}}
        <Alert @kind="success"><p>{{this.status}}</p></Alert>
      {{/if}}
      {{#if this.error}}
        <Alert @kind="error" @title="Could not save"><p
          >{{this.error}}</p></Alert>
      {{/if}}

      <Badge @tone={{if this.game.is_active "on" "off"}}>
        {{if this.game.is_active "Active" "Deactivated"}}
      </Badge>

      <form class="flex flex-wrap items-end gap-3" {{on "submit" this.save}}>
        <div class="min-w-64 flex-1">
          <Field
            @name="game-name"
            @label="Name"
            @required={{true}}
            @error={{this.fieldErrors.name}}
            as |f|
          >
            <input
              id={{f.id}}
              type="text"
              required
              maxlength="100"
              aria-invalid={{f.invalid}}
              aria-describedby={{f.describedBy}}
              value={{this.name}}
              class="w-full rounded-md border border-slate-300 px-3 py-2 dark:border-slate-600 dark:bg-slate-800"
              {{on "input" this.updateName}}
            />
          </Field>
        </div>

        <button
          type="submit"
          disabled={{this.busy}}
          class="rounded-md bg-brand-600 px-4 py-2 font-medium text-white hover:bg-brand-700 disabled:opacity-60"
        >
          {{if this.isSaving "Saving…" "Save"}}
        </button>

        <button
          type="button"
          disabled={{this.busy}}
          class="rounded-md border border-slate-300 px-4 py-2 hover:bg-slate-100 disabled:opacity-60 dark:border-slate-600 dark:hover:bg-slate-700"
          {{on "click" this.toggleActive}}
        >
          {{if this.game.is_active "Deactivate" "Reactivate"}}
        </button>
      </form>
    </div>
  </template>
}
