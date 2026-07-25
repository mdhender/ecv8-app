import Component from '@glimmer/component';
import { service } from '@ember/service';
import { tracked } from '@glimmer/tracking';
import { on } from '@ember/modifier';
import Alert from 'ec/components/ui/alert';
import Field from 'ec/components/ui/field';
import { ApiError } from 'ec/services/api';

/**
 * GameSetupForm is how a game master starts a game that has no state yet.
 *
 * The two seed words decide every random outcome the game will ever produce,
 * which is why they are shown rather than generated out of sight: a game master
 * who records them can replay a turn and check what the engine did.
 *
 * Their starting values come from the API, not from here. `default_seed` is
 * served alongside a game that has not been set up, so the numbers offered and
 * the numbers the server would have written when they are omitted cannot drift
 * apart — a default duplicated in the client would be wrong the first time the
 * engine changed its mind.
 *
 * Seed words are strings the whole way through, and are never parsed into
 * JavaScript numbers. A seed is a full-range 64-bit value and a JavaScript
 * number is a double, so anything above 2^53 would be rounded on its way back
 * to the server and the game would no longer replay from the seed it reports.
 */
export default class GameSetupForm extends Component {
  @service api;
  @service router;

  // Both start undefined and read through to the values the API offered, so an
  // untouched form submits exactly the server's own defaults.
  @tracked hiEdit;
  @tracked loEdit;

  @tracked error = null;
  @tracked fieldErrors = {};
  @tracked isSubmitting = false;

  get hi() {
    return this.hiEdit ?? this.args.game.default_seed?.hi ?? '';
  }

  get lo() {
    return this.loEdit ?? this.args.game.default_seed?.lo ?? '';
  }

  /**
   * The game is created only once both words are present.
   *
   * The inputs are `required`, so an empty one stops the submit and the browser
   * says which field and why, in the reader's own language — better than a
   * disabled button, which states that something is wrong without saying what.
   * This guard is the same rule for anything that gets past that.
   *
   * It decides completeness, not validity: what a seed word may contain is the
   * server's rule, and its answer is rendered against the field it names.
   */
  get isComplete() {
    return this.hi.trim() !== '' && this.lo.trim() !== '';
  }

  /**
   * The API reports a bad seed word against `seed.hi` or `seed.lo`. Those are
   * single keys with a dot in them, which a template path cannot express, so
   * they are unpacked here.
   */
  get hiError() {
    return this.fieldErrors['seed.hi'];
  }

  get loError() {
    return this.fieldErrors['seed.lo'];
  }

  updateHi = (event) => {
    this.hiEdit = event.target.value;
  };

  updateLo = (event) => {
    this.loEdit = event.target.value;
  };

  submit = async (event) => {
    event.preventDefault();
    if (!this.isComplete) {
      return;
    }
    this.error = null;
    this.fieldErrors = {};
    this.isSubmitting = true;
    try {
      await this.api.post(`/games/${this.args.game.id}/state`, {
        seed: { hi: this.hi.trim(), lo: this.lo.trim() },
      });
      // The route reloads the game, which now has a state, and this form is
      // replaced by it. Nothing is kept here that would survive that.
      this.router.refresh('games.detail');
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
      class="space-y-4 rounded-md border border-slate-200 p-4 dark:border-slate-700"
      {{on "submit" this.submit}}
    >
      <div>
        <h3 class="text-lg font-semibold">Set this game up</h3>
        <p class="mt-1 text-sm text-slate-600 dark:text-slate-300">
          The seed decides every random outcome in this game. The values below
          are the defaults; change them if you want a different game from the
          same starting position. They cannot be changed once the game begins.
        </p>
      </div>

      {{#if this.error}}
        <Alert @kind="error" @title="Could not set the game up">
          <p>{{this.error}}</p>
        </Alert>
      {{/if}}

      <div class="flex flex-wrap items-start gap-4">
        <div class="min-w-56 flex-1">
          <Field
            @name="seed-hi"
            @label="Seed (high)"
            @required={{true}}
            @hint="A whole number, 0 or greater."
            @error={{this.hiError}}
            as |f|
          >
            <input
              id={{f.id}}
              type="text"
              inputmode="numeric"
              required
              maxlength="20"
              aria-invalid={{f.invalid}}
              aria-describedby={{f.describedBy}}
              value={{this.hi}}
              class="w-full rounded-md border border-slate-300 px-3 py-2 font-mono dark:border-slate-600 dark:bg-slate-800"
              {{on "input" this.updateHi}}
            />
          </Field>
        </div>

        <div class="min-w-56 flex-1">
          <Field
            @name="seed-lo"
            @label="Seed (low)"
            @required={{true}}
            @hint="A whole number, 0 or greater."
            @error={{this.loError}}
            as |f|
          >
            <input
              id={{f.id}}
              type="text"
              inputmode="numeric"
              required
              maxlength="20"
              aria-invalid={{f.invalid}}
              aria-describedby={{f.describedBy}}
              value={{this.lo}}
              class="w-full rounded-md border border-slate-300 px-3 py-2 font-mono dark:border-slate-600 dark:bg-slate-800"
              {{on "input" this.updateLo}}
            />
          </Field>
        </div>
      </div>

      <button
        type="submit"
        disabled={{this.isSubmitting}}
        class="rounded-md bg-brand-600 px-4 py-2 font-medium text-white hover:bg-brand-700 disabled:opacity-60"
      >
        {{if this.isSubmitting "Starting…" "Start the game"}}
      </button>
    </form>
  </template>
}
