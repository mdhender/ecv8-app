import Component from '@glimmer/component';
import { service } from '@ember/service';
import { tracked } from '@glimmer/tracking';
import { on } from '@ember/modifier';
import Alert from 'ec/components/ui/alert';
import Field from 'ec/components/ui/field';
import { ApiError } from 'ec/services/api';

/** CreateGameForm adds a game. Names are unique. */
export default class CreateGameForm extends Component {
  @service api;
  @service router;

  @tracked name = '';
  @tracked error = null;
  @tracked fieldErrors = {};
  @tracked isSubmitting = false;

  updateName = (event) => {
    this.name = event.target.value;
  };

  submit = async (event) => {
    event.preventDefault();
    this.error = null;
    this.fieldErrors = {};
    this.isSubmitting = true;
    try {
      await this.api.post('/admin/games', { name: this.name });
      this.name = '';
      this.router.refresh('admin.games.index');
    } catch (error) {
      if (error instanceof ApiError) {
        this.error = error.message;
        this.fieldErrors = error.fields;
      } else {
        this.error = 'Could not reach the server. Try again.';
      }
    } finally {
      this.isSubmitting = false;
    }
  };

  <template>
    <form
      class="space-y-3 rounded-md border border-slate-200 p-4 dark:border-slate-700"
      {{on "submit" this.submit}}
    >
      <h3 class="text-lg font-semibold">Create a game</h3>

      {{#if this.error}}
        <Alert @kind="error" @title="Could not create the game">
          <p>{{this.error}}</p>
        </Alert>
      {{/if}}

      <div class="flex flex-wrap items-end gap-3">
        <div class="min-w-64 flex-1">
          <Field
            @name="new-game-name"
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
          disabled={{this.isSubmitting}}
          class="rounded-md bg-brand-600 px-4 py-2 font-medium text-white hover:bg-brand-700 disabled:opacity-60"
        >
          {{if this.isSubmitting "Creating…" "Create game"}}
        </button>
      </div>
    </form>
  </template>
}
